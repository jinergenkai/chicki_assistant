import 'dart:async';
import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../core/logger.dart';
import '../core/app_event_bus.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/local_llm_service.dart';
import '../services/llm_service.dart';

enum VoiceState {
  uninitialized,
  needsPermission,
  idle,
  listening,
  processing,
  speaking,
  detecting,
  error
}

class VoiceForegroundTaskHandler extends TaskHandler {
  // Note: Cannot use Get.find() in isolate, instantiate directly if needed
  final STTService _sttService = SpeechToTextService();
  final TTSService _ttsService = TextToSpeechService();
  final LLMService _gptService = LocalLLMService();

  StreamSubscription? _wakewordSub;
  String? _lastProcessedText;
  bool _isInitialized = false;

  VoiceState state = VoiceState.uninitialized;
  String recognizedText = '';
  String gptResponse = '';
  double rmsDB = 2.0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Communication is done via FlutterForegroundTask.sendDataToMain
    await initialize();
    _setupSTTListener();
    _setupRmsListener();

    _wakewordSub = eventBus.stream.where((event) => event.type == AppEventType.wakewordDetected).listen((event) {
      logger.info('Wakeword detected: ${event.payload}');
      if (state == VoiceState.idle) {
        startListening();
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic event - send status update
    FlutterForegroundTask.sendDataToMain({'status': 'running', 'state': state.name, 'timestamp': timestamp.toIso8601String()});
  }

  @override
  void onReceiveData(Object data) {
    // Handle commands from main isolate
    if (data is Map) {
      final command = data['command'] as String?;
      switch (command) {
        case 'startListening':
          startListening();
          break;
        case 'stopListening':
          stopListening();
          break;
        case 'stopSpeaking':
          stopSpeaking();
          break;
        default:
          logger.warning('Unknown command: $command');
      }
    }
  }

  Future<void> initialize() async {
    try {
      state = VoiceState.uninitialized;
      FlutterForegroundTask.sendDataToMain({'state': state.name});

      await PermissionUtils.checkMicrophone();
      state = VoiceState.needsPermission;
      FlutterForegroundTask.sendDataToMain({'state': state.name});

      await _sttService.initialize();
      await _ttsService.initialize();
      await _gptService.initialize();

      _isInitialized = true;
      logger.info('VoiceForegroundTaskHandler initialized successfully');
      state = VoiceState.idle;
      FlutterForegroundTask.sendDataToMain({'state': state.name});
    } catch (e) {
      logger.error('Failed to initialize VoiceForegroundTaskHandler', e);
      state = VoiceState.error;
      FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
      rethrow;
    }
  }

  void _setupSTTListener() {
    _sttService.onTextRecognized.listen((text) async {
      if (text.isNotEmpty) {
        _lastProcessedText = text;
        try {
          recognizedText = text;
          FlutterForegroundTask.sendDataToMain({'recognizedText': text});

          state = VoiceState.processing;
          FlutterForegroundTask.sendDataToMain({'state': state.name});
          logger.info('Processing speech input: $text');

          final response = await _gptService.generateResponse(text);
          logger.success('Got GPT response: $response');

          gptResponse = response;
          FlutterForegroundTask.sendDataToMain({'gptResponse': response});

          state = VoiceState.speaking;
          FlutterForegroundTask.sendDataToMain({'state': state.name});
          await _ttsService.speak(response);

          state = VoiceState.idle;
          FlutterForegroundTask.sendDataToMain({'state': state.name});
        } catch (e) {
          logger.error('Error processing voice input', e);
          state = VoiceState.error;
          FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
        }
      }
    });
  }

  void _setupRmsListener() {
    _sttService.onRmsChanged.listen((level) {
      rmsDB = level;
      FlutterForegroundTask.sendDataToMain({'rmsDB': level});
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('VoiceForegroundTaskHandler not initialized');
    }
    try {
      final hasPermission = await PermissionUtils.checkMicrophone();
      if (!hasPermission) {
        state = VoiceState.needsPermission;
        FlutterForegroundTask.sendDataToMain({'state': state.name});
        return;
      }

      await _sttService.startListening();
      state = VoiceState.listening;
      FlutterForegroundTask.sendDataToMain({'state': state.name});
      logger.info('VoiceForegroundTaskHandler: Started listening');
    } catch (e) {
      logger.error('Error starting voice listening', e);
      state = VoiceState.error;
      FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      await _sttService.stopListening();
      state = VoiceState.idle;
      FlutterForegroundTask.sendDataToMain({'state': state.name});
      logger.info('VoiceForegroundTaskHandler: Stopped listening');
    } catch (e) {
      logger.error('Error stopping voice listening', e);
      state = VoiceState.error;
      FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
      rethrow;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _ttsService.stop();
      state = VoiceState.idle;
      FlutterForegroundTask.sendDataToMain({'state': state.name});
      logger.info('Stopped speaking');
    } catch (e) {
      logger.error('Error stopping speech', e);
      state = VoiceState.error;
      FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
      rethrow;
    }
  }

  /// Starts continuous listening, splits input every 10s, sends to GPT, then TTS.
  Future<void> startContinuousListeningWithChunking() async {
    if (!_isInitialized) {
      throw Exception('VoiceForegroundTaskHandler not initialized');
    }
    try {
      final hasPermission = await PermissionUtils.checkMicrophone();
      if (!hasPermission) {
        state = VoiceState.needsPermission;
        FlutterForegroundTask.sendDataToMain({'state': state.name});
        return;
      }

      state = VoiceState.listening;
      FlutterForegroundTask.sendDataToMain({'state': state.name});
      logger.info('VoiceForegroundTaskHandler: Started continuous listening with chunking');

      await _sttService.startListening();

      String buffer = '';
      Timer? chunkTimer;

      StreamSubscription? sub;
      sub = _sttService.onTextRecognized.listen((text) async {
        if (text.isNotEmpty) {
          buffer += (buffer.isEmpty ? '' : ' ') + text;
        }
      });

      chunkTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (buffer.isNotEmpty) {
          final chunk = buffer.trim();
          buffer = '';
          try {
            state = VoiceState.processing;
            recognizedText = chunk;
            FlutterForegroundTask.sendDataToMain({'recognizedText': chunk, 'state': state.name});
            logger.info('Processing chunk: $chunk');
            final response = await _gptService.generateResponse(chunk);
            gptResponse = response;
            FlutterForegroundTask.sendDataToMain({'gptResponse': response});
            state = VoiceState.speaking;
            FlutterForegroundTask.sendDataToMain({'state': state.name});
            await _ttsService.speak(response);
            state = VoiceState.listening;
            FlutterForegroundTask.sendDataToMain({'state': state.name});
          } catch (e) {
            logger.error('Error processing chunk', e);
            state = VoiceState.error;
            FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
          }
        }
      });

      // Stop logic: you may want to expose a stop method to cancel timer/sub
      // For demo, auto-stop after 60s
      Future.delayed(const Duration(seconds: 60), () async {
        await sub?.cancel();
        chunkTimer?.cancel();
        await _sttService.stopListening();
        state = VoiceState.idle;
        FlutterForegroundTask.sendDataToMain({'state': state.name});
        logger.info('VoiceForegroundTaskHandler: Stopped continuous listening');
      });
    } catch (e) {
      logger.error('Error starting continuous listening', e);
      state = VoiceState.error;
      FlutterForegroundTask.sendDataToMain({'state': state.name, 'error': e.toString()});
      rethrow;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await stopListening();
    await stopSpeaking();
    _wakewordSub?.cancel();
    FlutterForegroundTask.sendDataToMain({'status': 'destroyed'});
  }
}