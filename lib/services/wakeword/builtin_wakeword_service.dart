import 'dart:async';
import 'dart:isolate';
import 'package:chicki_buddy/core/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:porcupine_flutter/porcupine.dart';
import '../wakeword_service.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:permission_handler/permission_handler.dart';

/// Example Porcupine-based wakeword service implementation.
/// Replace with actual Porcupine/Sherpa integration as needed.
class BuildtinWakewordService implements WakewordService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  final StreamController<WakewordEvent> _eventController = StreamController.broadcast();
  bool _isRunning = false;

  @override
  Future<void> start() async {
    if (_isRunning) return;
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_wakewordIsolateEntry, _receivePort!.sendPort);
    _receivePort!.listen(_handleIsolateMessage);
    _isRunning = true;
    _eventController.add(WakewordEvent(WakewordEventType.ready));
  }

  @override
  Future<void> stop() async {
    if (!_isRunning) return;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _isRunning = false;
    _eventController.add(WakewordEvent(WakewordEventType.stopped));
  }

  @override
  Stream<WakewordEvent> get events => _eventController.stream;

  @override
  void send(WakewordCommand command) {
    // Implement sending commands to isolate if needed
  }

  @override
  bool get isRunning => _isRunning;

  void _handleIsolateMessage(dynamic message) {
    if (message is Map && message['type'] == 'detected') {
      _eventController.add(WakewordEvent(WakewordEventType.detected, data: message['keyword']));
    } else if (message is Map && message['type'] == 'error') {
      _eventController.add(WakewordEvent(WakewordEventType.error, data: message['error']));
    }
  }
}

/// Entry point for the wakeword isolate.
/// This is a stub; replace with actual mic/audio and Porcupine/Sherpa logic.
void _wakewordIsolateEntry(SendPort sendPort) async {
  // Simulate continuous listening and detection loop
    await Future.delayed(const Duration(seconds: 20));
    // Simulate detection event
    sendPort.send({'type': 'detected', 'keyword': 'Hey AppName'});
}