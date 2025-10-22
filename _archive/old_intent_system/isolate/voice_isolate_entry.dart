// Dart

import 'dart:isolate';
import 'dart:ui';

import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/core/logger.dart';
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

  // Register ReceivePort for background isolate to receive intents from foreground
  final bgReceivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(bgReceivePort.sendPort, AppConstants.kBgTaskPortName);
  logger.info('[Background] Background isolate registered port: ${AppConstants.kBgTaskPortName}');

  bgReceivePort.listen((message) {
    logger.info('[Background] Received: $message');
       if (message is Map) {
      worker.handleCommand(Map<String, dynamic>.from(message));
    }
  });
}
