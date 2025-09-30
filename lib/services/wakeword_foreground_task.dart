import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground task handler for wakeword detection.
/// Extend this to run wakeword logic in the background.
class WakewordForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Initialize wakeword detection here if needed
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Periodically called while service is running
    // You can trigger wakeword detection or mic polling here
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup resources
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button press if needed
  }

  @override
  void onNotificationPressed() {
    // Handle notification tap if needed
  }
}