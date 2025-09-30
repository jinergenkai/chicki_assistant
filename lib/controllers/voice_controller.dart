import 'package:chicki_buddy/services/gpt_service.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import '../core/logger.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/local_llm_service.dart';
import '../services/llm_service.dart';
import '../services/porcupine_wakeword_service.dart';
import '../services/wakeword_service.dart';
import '../controllers/app_config.controller.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/wakeword_foreground_task.dart';

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

// Refactor: GetxController + Rx, giữ lại toàn bộ comment cũ để tiện phát triển feature sau này
class VoiceController extends GetxController {
  final AppConfigController appConfig = Get.find<AppConfigController>();
  final STTService _sttService = SpeechToTextService();
  String? _lastProcessedText;
  final TTSService _ttsService = TextToSpeechService();
  final LLMService _gptService = OpenAIService();
  PorcupineManager? _porcupineManager;

  // Wakeword service integration
  late final WakewordService _wakewordService = PorcupineWakewordService();
  StreamSubscription<WakewordEvent>? _wakewordSub;

  bool _isInitialized = false;
  final bool _isWakeWordEnabled = false;

  // Rx thay cho StreamController
  final state = VoiceState.uninitialized.obs;
  final recognizedText = ''.obs;
  final gptResponse = ''.obs;
  final rmsDB = (-2.0).obs;

  // Giữ lại comment về các StreamController cũ để tham khảo
  // final _stateController = StreamController<VoiceState>.broadcast();
  // final _textController = StreamController<String>.broadcast();
  // final _responseController = StreamController<String>.broadcast();

  // Stream<VoiceState> get stateStream => _stateController.stream;
  // Stream<String> get onTextRecognized => _textController.stream;
  // Stream<String> get onGptResponse => _responseController.stream;
  // bool get isInitialized => _isInitialized;
  // Stream<double> get onRmsChanged => _sttService.onRmsChanged;

  @override
  void onInit() {
    super.onInit();
    _setupSTTListener();
    _setupRmsListener();

    if (appConfig.enableWakewordBackground.value) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'wakeword_service_channel',
          channelName: 'Wakeword Service',
          channelDescription: 'Foreground service for wakeword detection',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [],
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
      FlutterForegroundTask.startService(
        notificationTitle: 'Wakeword Detection Running',
        notificationText: 'Listening for wakeword in background',
        callback: startCallback,
      );
      logger.info('Started Android foreground service for wakeword');
    } else {
      // Start in-app wakeword as fallback
      _wakewordService.start();
      _wakewordSub = _wakewordService.events.listen((event) {
        if (event.type == WakewordEventType.detected) {
          logger.info('Wakeword detected: ${event.data}');
          // Emit event to AppEventBus for other services/controllers to react
          eventBus.emit(AppEvent(AppEventType.wakewordDetected, event.data));
        } else if (event.type == WakewordEventType.error) {
          logger.error('Wakeword error: ${event.data}');
        }
      });
    }
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

      // Initialize Porcupine wake word detection
      // try {
      //   _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
      //     "3ZsjB+Lqz9YvUxjiPBL8lktSfYU27+Dy3HXQlzObXf+9PhpXizlbkw==",
      //     // ["assets/hey_chicki.ppn"], // Custom wake word model file
      //       [BuiltInKeyword.PICOVOICE, BuiltInKeyword.PORCUPINE],
      //     _wakeWordCallback
      //   );
      //   _isWakeWordEnabled = true;
      //   logger.info('Wake word detection initialized');
      //   await _porcupineManager?.start();
      // } catch (e) {
      //   logger.error('Failed to initialize wake word detection', e);
      //   // Continue without wake word detection
      //   _isWakeWordEnabled = false;
      // }

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
    _porcupineManager?.delete();
    super.dispose();
  }

  void _wakeWordCallback(int keywordIndex) {
    logger.info('Wake word detected! Index: $keywordIndex');
    // if (_stateController.isClosed) return;
    state.value = VoiceState.detecting;
    startListening();
  }

  Future<void> startWakeWordDetection() async {
    if (!_isInitialized || !_isWakeWordEnabled) {
      throw Exception('Wake word detection not initialized');
    }
    try {
      await _porcupineManager?.start();
      logger.info('Started wake word detection');
    } catch (e) {
      logger.error('Error starting wake word detection', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  Future<void> stopWakeWordDetection() async {
    if (!_isWakeWordEnabled) return;
    try {
      await _porcupineManager?.stop();
      logger.info('Stopped wake word detection');
    } catch (e) {
      logger.error('Error stopping wake word detection', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }
}