import 'dart:async';
import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:get/get.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';
import '../core/app_event_bus.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/local_llm_service.dart';
import '../services/llm_service.dart';
import '../services/voice_foreground_task_handler.dart';
import '../controllers/app_config.controller.dart';

// Callback function for foreground task
@pragma('vm:entry-point')
void startVoiceForegroundTask() {
  FlutterForegroundTask.setTaskHandler(VoiceForegroundTaskHandler());
}

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

  // Direct service instances (used when NOT in foreground mode)
  final STTService _sttService = SpeechToTextService();
  final TTSService _ttsService = TextToSpeechService();
  final LLMService _gptService = LocalLLMService();

  StreamSubscription? _wakewordSub;
  String? _lastProcessedText;
  void Function(Object)? _taskDataCallback;

  bool _isInitialized = false;
  bool _useForegroundService = false;

  // Rx observables for UI
  final state = VoiceState.uninitialized.obs;
  final recognizedText = ''.obs;
  final gptResponse = ''.obs;
  final rmsDB = (2.0).obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    
    // Set up foreground task data receiver (only once)
    _setupForegroundTaskReceiver();
    
    await initialize();
  }

  void _setupForegroundTaskReceiver() {
    // Listen to data from foreground service globally
    // This should only be set up once when controller initializes
    _taskDataCallback = (data) {
      if (data is Map && _useForegroundService) {
        _handleForegroundData(data);
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
  }

  @override
  void onClose() {
    _wakewordSub?.cancel();
    if (_useForegroundService) {
      stopForegroundService();
    }
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
    }
    super.onClose();
  }

  /// Initialize in direct mode (not using foreground service)
  Future<void> initialize() async {
    try {
      state.value = VoiceState.uninitialized;

      await PermissionUtils.checkMicrophone();
      state.value = VoiceState.needsPermission;

      // Initialize services for direct mode
      await _sttService.initialize();
      await _ttsService.initialize();
      await _gptService.initialize();

      _setupSTTListener();
      _setupRmsListener();

      _wakewordSub = eventBus.stream.where((event) => event.type == AppEventType.wakewordDetected).listen((event) {
        logger.info('Wakeword detected: ${event.payload}');
        if (state.value == VoiceState.idle) {
          startListening();
        }
      });

      _isInitialized = true;
      logger.info('Voice Controller initialized successfully (direct mode)');
      state.value = VoiceState.idle;
    } catch (e) {
      logger.error('Failed to initialize Voice Controller', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  /// Start using foreground service mode
  Future<void> startForegroundService() async {
    if (_useForegroundService) {
      logger.info('Foreground service already running');
      return;
    }

    try {
      // Request necessary permissions for foreground service
      final notificationPermission = await _requestNotificationPermission();
      if (!notificationPermission) {
        logger.error('Notification permission denied, cannot start foreground service');
        throw Exception('Notification permission is required for foreground service');
      }

      // Stop direct mode listeners
      _wakewordSub?.cancel();

      // Initialize foreground task
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'voice_assistant_channel',
          channelName: 'Voice Assistant Service',
          channelDescription: 'Voice assistant running in background',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      // Start the foreground service
      // Data reception is already set up in _setupForegroundTaskReceiver()
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Voice Assistant',
        notificationText: 'Listening for wake word...',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'stop', text: 'Stop'),
        ],
        callback: startVoiceForegroundTask,
      );

      _useForegroundService = true;
      logger.info('Foreground service started');
    } catch (e) {
      logger.error('Failed to start foreground service', e);
      rethrow;
    }
  }

  /// Check if foreground service is currently active
  bool get isForegroundServiceActive => _useForegroundService;

  /// Request notification permission (Android 13+)
  Future<bool> _requestNotificationPermission() async {
    await PermissionUtils.checkNotification();

    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // Battery optimization already disabled
    } else {
      // Request to disable battery optimization
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Check if notification permission is granted
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status == NotificationPermission.granted) {
      return true;
    }

    // Request notification permission
    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  /// Stop foreground service and return to direct mode
  Future<void> stopForegroundService() async {
    if (!_useForegroundService) return;

    try {
      await FlutterForegroundTask.stopService();
      _useForegroundService = false;

      // Restart direct mode
      await initialize();
      logger.info('Foreground service stopped, returned to direct mode');
    } catch (e) {
      logger.error('Failed to stop foreground service', e);
    }
  }

  void _handleForegroundData(Map data) {
    // Update observables from foreground service data
    if (data['state'] != null) {
      final stateName = data['state'] as String;
      state.value = VoiceState.values.firstWhere(
        (e) => e.name == stateName,
        orElse: () => VoiceState.idle,
      );
    }
    if (data['recognizedText'] != null) {
      recognizedText.value = data['recognizedText'] as String;
    }
    if (data['gptResponse'] != null) {
      gptResponse.value = data['gptResponse'] as String;
    }
    if (data['rmsDB'] != null) {
      rmsDB.value = (data['rmsDB'] as num).toDouble();
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

          // STT đã dừng (tự động sau khi nhận kết quả cuối), emit micStopped
          eventBus.emit(AppEvent(AppEventType.micStopped, null));
          logger.info('voice controller: STT finished, emitted micStopped event');

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
    if (_useForegroundService) {
      // Delegate to foreground service
      FlutterForegroundTask.sendDataToTask({'command': 'startListening'});
      return;
    }

    // Direct mode
    if (!_isInitialized) {
      throw Exception('Voice Controller not initialized');
    }
    try {
      final hasPermission = await PermissionUtils.checkMicrophone();
      if (!hasPermission) {
        state.value = VoiceState.needsPermission;
        return;
      }

      // Emit event để thông báo mic sắp được sử dụng
      eventBus.emit(AppEvent(AppEventType.micStarted, null));
      logger.info('voice controller: Emitted micStarted event');

      await _sttService.startListening();
      state.value = VoiceState.listening;
      logger.info('voice controller: Started listening (direct mode)');
    } catch (e) {
      logger.error('Error starting voice listening', e);
      // Nếu start thất bại, emit micStopped để Porcupine có thể resume
      eventBus.emit(AppEvent(AppEventType.micStopped, null));
      state.value = VoiceState.error;
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (_useForegroundService) {
      // Delegate to foreground service
      FlutterForegroundTask.sendDataToTask({'command': 'stopListening'});
      return;
    }

    // Direct mode
    try {
      await _sttService.stopListening();
      
      // Emit event để thông báo mic đã được release
      eventBus.emit(AppEvent(AppEventType.micStopped, null));
      logger.info('voice controller: Emitted micStopped event');
      
      state.value = VoiceState.idle;
      logger.info('voice controller: Stopped listening (direct mode)');
    } catch (e) {
      logger.error('Error stopping voice listening', e);
      // Vẫn emit micStopped ngay cả khi có lỗi để đảm bảo Porcupine resume
      eventBus.emit(AppEvent(AppEventType.micStopped, null));
      state.value = VoiceState.error;
      rethrow;
    }
  }

  Future<void> stopSpeaking() async {
    if (_useForegroundService) {
      // Delegate to foreground service
      FlutterForegroundTask.sendDataToTask({'command': 'stopSpeaking'});
      return;
    }

    // Direct mode
    try {
      await _ttsService.stop();
      state.value = VoiceState.idle;
      logger.info('Stopped speaking (direct mode)');
    } catch (e) {
      logger.error('Error stopping speech', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  /// Starts continuous listening, splits input every 10s, sends to GPT, then TTS.
  /// Note: This only works in direct mode, not supported in foreground service mode yet
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
