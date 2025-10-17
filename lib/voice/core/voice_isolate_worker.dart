// Dart

import 'dart:isolate';
import 'package:chicki_buddy/voice/models/voice_intent_payload.dart';
import 'package:chicki_buddy/voice/models/voice_action_event.dart';
import 'package:chicki_buddy/voice/handlers/intent_handler.dart';
import 'package:chicki_buddy/voice/models/voice_state_context.dart';

class VoiceIsolateWorker {
  final SendPort _mainSendPort;
  Map<String, dynamic>? _config;

  VoiceIsolateWorker(this._mainSendPort);

  void handleCommand(Map<String, dynamic> message) {
    final command = message['command'] as String?;
    try {
      switch (command) {
        case 'dispatchIntent':
          _handleDispatchIntent(message);
          break;
        case 'updateConfig':
          _handleUpdateConfig(message);
          break;
        case 'shutdown':
          _handleShutdown();
          break;
        default:
          _sendError('Unknown command: $command');
      }
    } catch (e) {
      _sendError('Error handling command $command: $e');
    }
  }

  Future<void> _handleDispatchIntent(Map<String, dynamic> message) async {
    final payloadData = message['payload'] as Map<String, dynamic>;
    final payload = VoiceIntentPayload.fromJson(payloadData);

    _sendStatus('processing', {'intent': payload.intent});

    final state = VoiceStateContext(currentScreen: 'idle');
    final handlers = <String, IntentHandler>{
      'selectBook': SelectBookHandler(),
      'selectTopic': SelectTopicHandler(),
      'nextVocab': NextVocabHandler(),
      'readAloud': ReadAloudHandler(),
    };

    final handler = handlers[payload.intent];
    HandlerResult result;
    if (handler != null) {
      result = await handler.execute(payload, state);
    } else {
      result = HandlerResult(success: false, data: {'intent': payload.intent, 'slots': payload.slots});
    }

    final actionEvent = VoiceActionEvent(
      action: payload.intent,
      data: result.data,
      requiresUI: true,
    );

    _sendActionEvent(actionEvent);
    _sendStatus('completed', {'intent': payload.intent});
  }

  void _handleUpdateConfig(Map<String, dynamic> message) {
    _config = message['config'] as Map<String, dynamic>?;
    _sendStatus('config_updated', null);
  }

  void _handleShutdown() {
    _sendStatus('shutting_down', null);
    // Cleanup resources here
  }

  void _sendActionEvent(VoiceActionEvent event) {
    _mainSendPort.send({
      'type': 'actionEvent',
      'event': event.toJson(),
    });
  }

  void _sendStatus(String status, dynamic data) {
    _mainSendPort.send({
      'type': 'status',
      'status': status,
      'data': data,
    });
  }

  void _sendError(String error) {
    _mainSendPort.send({
      'type': 'error',
      'error': error,
    });
  }
}