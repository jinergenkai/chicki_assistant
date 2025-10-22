// Dart

import 'dart:async';
import 'dart:isolate';

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/voice/models/voice_action_event.dart';
import '../../core/logger.dart';

typedef ActionEventCallback = void Function(VoiceActionEvent event);
typedef StatusUpdateCallback = void Function(String status, dynamic data);

class VoiceIsolateChannel {
  SendPort? isolateSendPort;
  final Completer<void> readyCompleter;
  final ActionEventCallback? onActionEvent;
  final StatusUpdateCallback? onStatusUpdate;

  VoiceIsolateChannel({
    required this.readyCompleter,
    this.onActionEvent,
    this.onStatusUpdate,
  });

  void handleMessage(dynamic message) {
    if (message is SendPort) {
      isolateSendPort = message;
      logger.info('VoiceIsolateChannel: Received SendPort from isolate');
      if (!readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
      return;
    }

    if (message is Map) {
      final type = message['type'] as String?;

      switch (type) {
        case 'ready':
          logger.info('VoiceIsolateChannel: Isolate is ready');
          break;

        case 'actionEvent':
          final eventData = message['event'] as Map<String, dynamic>;
          final event = VoiceActionEvent.fromJson(eventData);
          eventBus.emit(AppEvent(AppEventType.voiceAction, event));
          onActionEvent?.call(event);
          break;

        case 'status':
          final status = message['status'] as String;
          final data = message['data'];
          onStatusUpdate?.call(status, data);
          logger.info('VoiceIsolateChannel: Status - $status');
          break;

        case 'error':
          final error = message['error'] as String;
          logger.error('VoiceIsolateChannel: Isolate error - $error');
          break;

        default:
          logger.warning('VoiceIsolateChannel: Unknown message type: $type');
      }
    }
  }
}