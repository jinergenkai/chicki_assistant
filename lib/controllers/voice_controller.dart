import 'dart:async';
import 'package:chicki_buddy/services/sherpa-onnx/index.dart';
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
import '../services/wakeword/porcupine_wakeword_service.dart';
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
  StreamSubscription? _wakewordSub;

  void Function(Object)? _taskDataCallback;
  bool _useForegroundService = false;

  // Rx observables for UI
  final state = VoiceState.uninitialized.obs;
  final recognizedText = ''.obs;
  final gptResponse = ''.obs;
  final rmsDB = (2.0).obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _startForegroundOnly();
  }

  @override
  void onClose() {
    if (_useForegroundService) {
      stopForegroundService();
    }
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
    }
    _wakewordSub?.cancel();
    super.onClose();
  }

  /// Khởi tạo foreground service và chỉ sử dụng foreground isolate
  Future<void> _startForegroundOnly() async {
    try {
      state.value = VoiceState.uninitialized;

      // Permission cho mic và notification
      await PermissionUtils.checkMicrophone();
      final notificationPermission = await _requestNotificationPermission();
      if (!notificationPermission) {
        logger.error('Notification permission denied, cannot start foreground service');
        throw Exception('Notification permission is required for foreground service');
      }

      _wakewordSub = eventBus.stream.where((event) => event.type == AppEventType.wakewordDetected).listen((event) {
        logger.info('Wakeword detected: ${event.payload}');
        if (state.value == VoiceState.idle || state.value == VoiceState.error) {
          startListening();
        }
      });

      // Init foreground task
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

      _taskDataCallback = (data) {
        if (data is Map && _useForegroundService) {
          _handleForegroundData(data);
        }
      };
      FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Voice Assistant',
        notificationText: 'Ready to start listening',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'start', text: 'Start'),
          const NotificationButton(id: 'stop', text: 'Stop'),
        ],
        callback: startVoiceForegroundTask,
      );

      FlutterForegroundTask.sendDataToTask({
        'config': appConfig.toJson(),
      });

      _useForegroundService = true;
      logger.info('Foreground service started (foreground-only mode)');
      state.value = VoiceState.idle;
    } catch (e) {
      logger.error('Failed to start foreground service', e);
      state.value = VoiceState.error;
      rethrow;
    }
  }

  /// Request notification permission (Android 13+)
  Future<bool> _requestNotificationPermission() async {
    await PermissionUtils.checkNotification();

    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // Battery optimization already disabled
    } else {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status == NotificationPermission.granted) {
      return true;
    }

    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  /// Getter trạng thái foreground service (giữ lại cho UI cũ)
  bool get isForegroundServiceActive => _useForegroundService;

  /// Khởi tạo foreground service (giữ lại cho UI cũ)
  Future<void> startForegroundService() async {
    await _startForegroundOnly();
  }

  /// Stop foreground service
  Future<void> stopForegroundService() async {
    if (!_useForegroundService) return;

    try {
      await FlutterForegroundTask.stopService();
      _useForegroundService = false;
      logger.info('Foreground service stopped');
      state.value = VoiceState.uninitialized;
    } catch (e) {
      logger.error('Failed to stop foreground service', e);
    }
  }

  void _handleForegroundData(Map data) {
    // Wakeword, mic lifecycle, state, recognizedText, gptResponse, rmsDB
    if (data['wakewordDetected'] == true) {
      logger.info('VoiceController: Wakeword detected from foreground task');
    }
    if (data['micLifecycle'] != null) {
      final lifecycle = data['micLifecycle'] as String;
      logger.info('VoiceController: Received micLifecycle from foreground: $lifecycle');
      if (lifecycle == 'started') {
        eventBus.emit(AppEvent(AppEventType.micStarted, null));
      } else if (lifecycle == 'stopped') {
        eventBus.emit(AppEvent(AppEventType.micStopped, null));
      }
    }
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

  /// Gửi lệnh sang foreground isolate
  Future<void> startListening() async {
    if (_useForegroundService) {
      logger.info('startListening to foreground service');
      FlutterForegroundTask.sendDataToTask({'command': 'startListening'});
    }
  }

  Future<void> stopListening() async {
    if (_useForegroundService) {
      FlutterForegroundTask.sendDataToTask({'command': 'stopListening'});
    }
  }

  Future<void> stopSpeaking() async {
    if (_useForegroundService) {
      FlutterForegroundTask.sendDataToTask({'command': 'stopSpeaking'});
    }
  }
}
