import 'dart:async';

enum AppEventType {
  // Wakeword
  wakewordDetected,
  assistantMessage,
  
  // Microphone lifecycle events
  micStarted,  // Khi STT bắt đầu sử dụng mic
  micStopped,  // Khi STT dừng sử dụng mic
}

class AppEvent {
  final AppEventType type;
  final dynamic payload;
  AppEvent(this.type, this.payload);
}

class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) => _controller.add(event);
}

final eventBus = AppEventBus();