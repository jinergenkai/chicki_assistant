import 'dart:async';

import 'package:chicki_buddy/services/gpt_service.dart';
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
  detecting,  // Added for wake word detection
  error
}

class VoiceController extends GetxController {
  final AppConfigController appConfig = Get.find<AppConfigController>();
  final STTService _sttService = SpeechToTextService();
  String? _lastProcessedText;
  final TTSService _ttsService = TextToSpeechService();
  final LLMService _gptService = OpenAIService();
  StreamSubscription? _wakewordSub;

  bool _isInitialized = false;

  // Rx thay cho StreamController
  final state = VoiceState.uninitialized.obs;
  final recognizedText = ''.obs;
  final gptResponse = ''.obs;
  final rmsDB = (-2.0).obs;

  @override
  void onInit() {
    super.onInit();
    _setupSTTListener();
    _setupRmsListener();

    _wakewordSub = eventBus.stream
      .where((event) => event.type == AppEventType.wakewordDetected)
      .listen((event) {
        logger.info('Wakeword detected: ${event.payload}');
        print(state.value);
        if (state.value == VoiceState.idle) {
          startListening();
        }
      });
  }

  Future<void> initialize() async {
    try {
      state.value = VoiceState.uninitialized;

      // Check microphone permission first
      final micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) {
        state.value = VoiceState.needsPermission;
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          throw Exception('Microphone permission denied');
        }
      }

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
        if (_lastProcessedText == text) {
          logger.info('Duplicate speech input detected, skipping: $text');
          return;
        }
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
      logger.info('VoiceController: rmsDB=$level');
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('Voice Controller not initialized');
    }
    try {
      // Double check microphone permission
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        state.value = VoiceState.needsPermission;
        throw Exception('Microphone permission not granted');
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

  void disposeController() {
    super.dispose();
  }

  @override
  void dispose() {
    _wakewordSub?.cancel();
    super.dispose();
  }

}