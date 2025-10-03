import 'dart:async';

import 'package:chicki_buddy/services/gpt_service.dart';
import 'package:chicki_buddy/services/mock_speech_to_text_service.dart';
import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/local_llm_service.dart';
import '../services/llm_service.dart';
import '../core/app_event_bus.dart';
import '../services/wakeword_service.dart';
import '../controllers/app_config.controller.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/wakeword/wakeword_foreground_task.dart';

enum VoiceState {
  uninitialized,
  needsPermission,
  idle,
  listening,
  processing,
  speaking,
  detecting, // Added for wake word detection
  error
}

class VoiceController extends GetxController {
  final AppConfigController appConfig = Get.find<AppConfigController>();
  final STTService _sttService = SpeechToTextService();
  final TTSService _ttsService = TextToSpeechService();
  final LLMService _gptService = LocalLLMService();

  StreamSubscription? _wakewordSub;
  String? _lastProcessedText;

  bool _isInitialized = false;

  // Rx thay cho StreamController
  final state = VoiceState.uninitialized.obs;
  final recognizedText = ''.obs;
  final gptResponse = ''.obs;
  final rmsDB = (2.0).obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _setupSTTListener();
    _setupRmsListener();

    _wakewordSub = eventBus.stream.where((event) => event.type == AppEventType.wakewordDetected).listen((event) {
      logger.info('Wakeword detected: ${event.payload}');
      print(state.value);
      if (state.value == VoiceState.idle) {
        startListening();
      }
    });
    await initialize();
  }

  Future<void> initialize() async {
    try {
      state.value = VoiceState.uninitialized;

      await PermissionUtils.checkMicrophone();
      state.value = VoiceState.needsPermission;

      // Initialize all services
      await _sttService.initialize();
      await _ttsService.initialize();
      await _gptService.initialize();

      _isInitialized = true;
      logger.info('Voice Controller initialized successfully');
      state.value = VoiceState.idle;
    } catch (e) {
      logger.error('Failed to initialize Voice Controller', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  void _setupSTTListener() {
    _sttService.onTextRecognized.listen((text) async {
      if (text.isNotEmpty) {
        // Chặn duplicate message
        // if (_lastProcessedText == text) {
        //   logger.info('Duplicate speech input detected, skipping: $text');
        //   return;
        // }
        _lastProcessedText = text;
        try {
          // Emit recognized text
          recognizedText.value = text;

          state.value = VoiceState.processing;
          logger.info('Processing speech input: $text');

          // Get response from GPT
          final response = await _gptService.generateResponse(text);
          logger.success('Got GPT response: $response');

          // Emit GPT response
          gptResponse.value = response;

          // Speak the response
          state.value = VoiceState.speaking;
          await _ttsService.speak(response);

          state.value = VoiceState.idle;
        } catch (e) {
          logger.error('Error processing voice input', e);
          state.value = VoiceState.error;
        }
      }
    });
  }

  void _setupRmsListener() {
    _sttService.onRmsChanged.listen((level) {
      rmsDB.value = level;
      // logger.info('VoiceController: rmsDB=$level');
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('Voice Controller not initialized');
    }
    try {
      // Double check microphone permission
      final hasPermission = await PermissionUtils.checkMicrophone();
      if (!hasPermission) {
        state.value = VoiceState.needsPermission;
      }

      await _sttService.startListening();
      state.value = VoiceState.listening;
      logger.info('voice controller: Started listening');
    } catch (e) {
      logger.error('Error starting voice listening', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      await _sttService.stopListening();
      state.value = VoiceState.idle;
      logger.info('voice controller: Stopped listening');
    } catch (e) {
      logger.error('Error stopping voice listening', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _ttsService.stop();
      state.value = VoiceState.idle;
      logger.info('Stopped speaking');
    } catch (e) {
      logger.error('Error stopping speech', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  // Không đóng các StreamController vì VoiceController là singleton và có thể còn được sử dụng ở nơi khác.
  // _stateController.close();
  // _textController.close();
  // _responseController.close();

  // @override
  // void dispose() {
  //   _sttService.stopListening();
  //   _ttsService.stop();
  //   _wakewordSub?.cancel();
  //   super.dispose();
  // }

  /// Starts continuous listening, splits input every 10s, sends to GPT, then TTS.
  Future<void> startContinuousListeningWithChunking() async {
    if (!_isInitialized) {
      throw Exception('Voice Controller not initialized');
    }
    try {
      final hasPermission = await PermissionUtils.checkMicrophone();
      if (!hasPermission) {
        state.value = VoiceState.needsPermission;
      }

      state.value = VoiceState.listening;
      logger.info('voice controller: Started continuous listening with chunking');

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
            state.value = VoiceState.processing;
            recognizedText.value = chunk;
            logger.info('Processing chunk: $chunk');
            final response = await _gptService.generateResponse(chunk);
            gptResponse.value = response;
            state.value = VoiceState.speaking;
            await _ttsService.speak(response);
            state.value = VoiceState.listening;
          } catch (e) {
            logger.error('Error processing chunk', e);
            state.value = VoiceState.error;
          }
        }
      });

      // Stop logic: you may want to expose a stop method to cancel timer/sub
      // For demo, auto-stop after 60s
      Future.delayed(const Duration(seconds: 60), () async {
        await sub?.cancel();
        chunkTimer?.cancel();
        await _sttService.stopListening();
        state.value = VoiceState.idle;
        logger.info('voice controller: Stopped continuous listening');
      });
    } catch (e) {
      logger.error('Error starting continuous listening', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }
}
