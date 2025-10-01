import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground task handler for wakeword detection.
/// Extend this to run wakeword logic in the background.
class WakewordForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onDestroy(DateTime timestamp) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) {
    // TODO: implement onStart
    throw UnimplementedError();
  }
}