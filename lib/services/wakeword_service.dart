import 'dart:isolate';

/// Abstract class for wakeword detection service.
/// Handles isolate communication and platform-agnostic interface.
abstract class WakewordService {
  /// Start the wakeword detection isolate.
  Future<void> start();

  /// Stop the wakeword detection isolate.
  Future<void> stop();

  /// Stream of wakeword events (e.g., detected, error).
  Stream<WakewordEvent> get events;

  /// Send configuration or control messages to the isolate.
  void send(WakewordCommand command);

  /// Optionally, provide a way to check if the service is running.
  bool get isRunning;
}

/// Wakeword event types sent from the isolate to the main isolate.
class WakewordEvent {
  final WakewordEventType type;
  final dynamic data;

  WakewordEvent(this.type, {this.data});
}

enum WakewordEventType {
  detected, // Wakeword detected
  error,    // Error occurred
  ready,    // Service ready
  stopped,  // Service stopped
}

/// Commands sent from main isolate to the wakeword isolate.
class WakewordCommand {
  final WakewordCommandType type;
  final dynamic data;

  WakewordCommand(this.type, {this.data});
}

enum WakewordCommandType {
  configure, // Update config/model
  pause,     // Pause detection
  resume,    // Resume detection
  stop,      // Stop detection
}