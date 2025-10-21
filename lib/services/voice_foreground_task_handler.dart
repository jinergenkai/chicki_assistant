import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/llm_intent_classifier_service.dart';
import 'package:chicki_buddy/services/sherpa-onnx/index.dart';
import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/logger.dart';
import '../core/app_event_bus.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/local_llm_service.dart';
import '../services/llm_service.dart';
// Intent system
import 'package:chicki_buddy/services/intent/intent_system_service.dart';
import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:chicki_buddy/voice/dispatcher/voice_intent_dispatcher.dart';

enum VoiceState { uninitialized, needsPermission, idle, listening, processing, speaking, detecting, error }

class VoiceForegroundTaskHandler extends TaskHandler {
  // Note: Cannot use Get.find() in isolate, instantiate directly if needed
  final STTService _sttService = SpeechToTextService();
  final TTSService _ttsService = TextToSpeechService();
  // final TTSService _ttsService = SherpaTtsService();
  // final LLMService _gptService = LocalLLMService();
  final LLMIntentClassifierService _intentClassifier = LLMIntentClassifierService();

  final fgReceivePort = ReceivePort();
  // Intent system instance
  IntentSystemService? _intentSystem;

  Future<void> _initIntentSystem() async {
    final jsonStr = await rootBundle.loadString('assets/data/graph.json');
    final graph = WorkflowGraph.fromJson(jsonDecode(jsonStr));
    final dispatcher = VoiceIntentDispatcher();
    _intentSystem = IntentSystemService(
      workflowGraph: graph,
      dispatcher: dispatcher,
    );
  }

  SendPort? bgPort;

  StreamSubscription? _wakewordSub;
  bool _isInitialized = false;

  VoiceState state = VoiceState.uninitialized;
  String recognizedText = '';
  String gptResponse = '';
  double rmsDB = 2.0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
  
    // Communication is done via FlutterForegroundTask.sendDataToMain
    await initialize();
    _setupSTTListener();
    _setupRmsListener();

    await _initIntentSystem();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic event - send status update
    FlutterForegroundTask.sendDataToMain({'status': 'running', 'state': state.name, 'timestamp': timestamp.toIso8601String()});
  }

  @override
  Future<void> onReceiveData(Object data) async {
    // Handle commands from main isolate
    logger.info('ForegroundTask: Received data: $data');
    if (data is Map) {
      // Handle bridge service request
      if (data['bridge'] == 'book') {
        final action = data['action'] as String?;
        switch (action) {
          case 'listBook':
            _intentSystem?.triggerIntent('listBook').then((event) {
              FlutterForegroundTask.sendDataToMain({
                'bridge': 'book',
                'action': 'listBook',
                'result': jsonEncode(event.data['books'] ?? []),
              });
            });
            break;
        }
        return;
      }
      // Handle config update
      if (data['config'] != null) {
        final config = AppConfigController.fromJson(data['config']);
        SpeechToTextService().setConfig(config);
        TextToSpeechService().setConfig(config);
        LocalLLMService().setConfig(config);
        FlutterForegroundTask.sendDataToMain({'status': 'config_set'});
      }

      // Handle wakeword detection từ main isolate
      if (data['wakewordDetected'] == true) {
        logger.info('ForegroundTask: Wakeword detected from main isolate');
        if (state == VoiceState.idle) {
          startListening();
        }
        return;
      }

      // Handle commands
      final command = data['command'] as String?;
      switch (command) {
        case 'startListening':
          FlutterForegroundTask.sendDataToMain({'status': 'listening'});
          FlutterForegroundTask.updateService(
            notificationText: 'Listening...',
            notificationButtons: [
              const NotificationButton(id: 'stop', text: 'Stop'),
            ],
          );
          startListening();
          break;
        case 'stopListening':
          FlutterForegroundTask.updateService(
            notificationText: 'Stopped',
            notificationButtons: [
              const NotificationButton(id: 'start', text: 'Start'),
            ],
          );
          stopListening();
          break;
        case 'stopSpeaking':
          stopSpeaking();
          break;
        default:
          if (command != null) {
            logger.warning('ForegroundTask: Unknown command: $command');
          }
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
      // await _gptService.initialize();

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
        try {
          recognizedText = text;
          FlutterForegroundTask.sendDataToMain({'recognizedText': text});

          // STT đã dừng (tự động sau khi nhận kết quả cuối), gửi micStopped về main
          FlutterForegroundTask.sendDataToMain({'micLifecycle': 'stopped'});
          logger.info('ForegroundTask: STT finished, sent micStopped to main isolate');

          state = VoiceState.processing;
          FlutterForegroundTask.sendDataToMain({'state': state.name});
          logger.info('Processing speech input: $text');

          // Phân tích intent bằng LLM
          final response = await _intentClassifier.classify(text);
          logger.success('LLM intent result: $response');

          // Xử lý intent trực tiếp bằng intent system (không dùng isolate nữa)
          if (_intentSystem != null && response['intent'] != null) {
            _intentSystem!
                .triggerIntent(
              response['intent'] as String,
              slots: response['slots'] is Map ? Map<String, dynamic>.from(response['slots']) : {},
            )
                .then((event) {
              // Emit event về main isolate nếu cần
              FlutterForegroundTask.sendDataToMain({'voiceAction': event.toJson()});
            });
          }
          FlutterForegroundTask.sendDataToMain({'gptResponse': response['intent']});

          state = VoiceState.speaking;
          FlutterForegroundTask.sendDataToMain({'state': state.name});
          await _ttsService.speak(response['intent']);

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

      // Gửi micStarted về main isolate để pause wakeword
      FlutterForegroundTask.sendDataToMain({'micLifecycle': 'started'});
      logger.info('ForegroundTask: Sent micStarted to main isolate');

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

      // Gửi micStopped về main isolate để resume wakeword
      FlutterForegroundTask.sendDataToMain({'micLifecycle': 'stopped'});
      logger.info('ForegroundTask: Sent micStopped to main isolate');

      state = VoiceState.idle;
      FlutterForegroundTask.sendDataToMain({'state': state.name});
      logger.info('VoiceForegroundTaskHandler: Stopped listening');
    } catch (e) {
      logger.error('Error stopping voice listening', e);
      // Vẫn gửi micStopped để đảm bảo wakeword resume
      FlutterForegroundTask.sendDataToMain({'micLifecycle': 'stopped'});
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

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await stopListening();
    await stopSpeaking();
    _wakewordSub?.cancel();
    FlutterForegroundTask.sendDataToMain({'status': 'destroyed'});
    logger.info('ForegroundTask: Destroyed and cleaned up');
  }
}
