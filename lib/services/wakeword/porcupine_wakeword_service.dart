import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:get/get.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../wakeword_service.dart';
import '../../core/app_event_bus.dart';
import '../../core/logger.dart';

class PorcupineWakewordService extends GetxService implements WakewordService {
  PorcupineManager? _porcupineManager;
  bool _isRunning = false;

  @override
  void onInit() async {
    await PermissionUtils.checkMicrophone();
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        "3ZsjB+Lqz9YvUxjiPBL8lktSfYU27+Dy3HXQlzObXf+9PhpXizlbkw==",
        ["assets/hey_chicky.ppn"],
        _wakeWordCallback,
      );
      await _porcupineManager?.start();
      logger.info('PorcupineWakewordService: PorcupineManager initialized');
    } catch (e) {
      logger.error('PorcupineWakewordService: Failed to initialize', e);
    }
    super.onInit();
  }

  @override
  Future<void> start() async {
    if (_isRunning) return;
    try {
      await _porcupineManager?.start();
      _isRunning = true;
      eventBus.emit(AppEvent(AppEventType.wakewordDetected, 'ready'));
      logger.info('PorcupineWakewordService: Wake word detection started');
    } catch (e) {
      eventBus.emit(AppEvent(AppEventType.wakewordDetected, e));
      logger.error('PorcupineWakewordService: Failed to start', e);
    }
  }

  @override
  Future<void> stop() async {
    if (!_isRunning) return;
    try {
      await _porcupineManager?.stop();
      _isRunning = false;
      eventBus.emit(AppEvent(AppEventType.wakewordDetected, 'stopped'));
      logger.info('PorcupineWakewordService: Wake word detection stopped');
    } catch (e) {
      eventBus.emit(AppEvent(AppEventType.wakewordDetected, e));
      logger.error('PorcupineWakewordService: Failed to stop', e);
    }
  }

  @override
  Stream<WakewordEvent> get events => eventBus.stream
      .where((event) => event.type == AppEventType.wakewordDetected)
      .map((event) {
        final data = event.payload;
        if (data == 'ready') {
          return WakewordEvent(WakewordEventType.ready);
        } else if (data == 'stopped') {
          return WakewordEvent(WakewordEventType.stopped);
        } else if (data is int) {
          return WakewordEvent(WakewordEventType.detected, data: data);
        } else if (data is String && data.contains('permission')) {
          return WakewordEvent(WakewordEventType.error, data: data);
        } else if (data is Exception || data is Error) {
          return WakewordEvent(WakewordEventType.error, data: data);
        }
        return WakewordEvent(WakewordEventType.detected, data: data);
      });

  @override
  void send(WakewordCommand command) {
    // Chưa cần implement, nếu cần cấu hình lại thì xử lý ở đây
  }

  @override
  bool get isRunning => _isRunning;

  void _wakeWordCallback(int keywordIndex) {
    logger.info('PorcupineWakewordService: Wake word detected! Index: $keywordIndex');
    eventBus.emit(AppEvent(AppEventType.wakewordDetected, keywordIndex));
  }
}