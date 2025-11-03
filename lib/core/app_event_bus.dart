import 'dart:async';
import 'dart:isolate';

import 'package:chicki_buddy/core/logger.dart';

enum AppEventType {
  // Wakeword
  wakewordDetected,
  assistantMessage,
  // Microphone lifecycle events
  micStarted,
  micStopped,
  // Voice intent and actions
  voiceIntent,
  voiceAction,

  // Book bridge results
  bookBridgeResult,

  // Intent state
  intentState,
  handlerState,
}

class AppEvent {
  final AppEventType type;
  final dynamic payload;
  AppEvent(this.type, this.payload);
}

class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) {
    logger.info('[EventBus - ${Isolate.current.debugName}] emit: ${event.type} | ${event.payload}');
    _controller.add(event);
  }
}

final eventBus = AppEventBus();