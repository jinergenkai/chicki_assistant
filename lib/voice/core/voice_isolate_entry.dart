// Dart

import 'dart:isolate';

import 'package:chicki_buddy/voice/core/voice_isolate_worker.dart';

void voiceIsolateEntryPoint(SendPort mainSendPort) {
  final isolateReceivePort = ReceivePort();

  mainSendPort.send(isolateReceivePort.sendPort);
  mainSendPort.send({'type': 'ready'});

  final worker = VoiceIsolateWorker(mainSendPort);

  isolateReceivePort.listen((message) {
    if (message is Map) {
      worker.handleCommand(Map<String, dynamic>.from(message));
    }
  });
}