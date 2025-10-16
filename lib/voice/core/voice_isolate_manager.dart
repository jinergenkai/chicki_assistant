import 'dart:async';
import 'dart:isolate';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/voice/handlers/intent_handler.dart';
import 'package:chicki_buddy/voice/models/voice_state_context.dart';
import 'package:flutter/foundation.dart';
import '../../core/logger.dart';
import '../models/voice_intent_payload.dart';
import '../models/voice_action_event.dart';

/// Manages the background isolate for voice intent processing
class VoiceIsolateManager {
  static final VoiceIsolateManager _instance = VoiceIsolateManager._internal();
  factory VoiceIsolateManager() => _instance;
  VoiceIsolateManager._internal();

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  
  final _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  bool get isRunning => _isolate != null && _isolateSendPort != null;

  /// Callback for receiving action events from isolate
  void Function(VoiceActionEvent)? onActionEvent;
  
  /// Callback for receiving status updates from isolate
  void Function(String, dynamic)? onStatusUpdate;

  /// Start the background isolate
  Future<void> start() async {
    if (isRunning) {
      logger.warning('VoiceIsolateManager: Already running');
      return;
    }

    try {
      logger.info('VoiceIsolateManager: Starting background isolate...');
      
      // Create receive port for main isolate
      _mainReceivePort = ReceivePort();
      
      // Spawn the isolate
      _isolate = await Isolate.spawn(
        _voiceIsolateEntryPoint,
        _mainReceivePort!.sendPort,
        debugName: 'VoiceIntentIsolate',
      );

      // Listen for messages from isolate
      _mainReceivePort!.listen(_handleIsolateMessage);

      logger.info('VoiceIsolateManager: Background isolate spawned');
    } catch (e) {
      logger.error('VoiceIsolateManager: Failed to start isolate', e);
      rethrow;
    }
  }

  /// Stop the background isolate
  Future<void> stop() async {
    if (!isRunning) {
      logger.warning('VoiceIsolateManager: Not running');
      return;
    }

    try {
      logger.info('VoiceIsolateManager: Stopping background isolate...');
      
      // Send shutdown command
      if (_isolateSendPort != null) {
        _isolateSendPort!.send({'command': 'shutdown'});
      }

      // Wait a bit for graceful shutdown
      await Future.delayed(const Duration(milliseconds: 100));

      // Kill isolate
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;

      // Close receive port
      _mainReceivePort?.close();
      _mainReceivePort = null;
      
      _isolateSendPort = null;

      logger.info('VoiceIsolateManager: Background isolate stopped');
    } catch (e) {
      logger.error('VoiceIsolateManager: Error stopping isolate', e);
    }
  }

  /// Send intent to background isolate for processing
  Future<void> dispatchIntent(VoiceIntentPayload payload) async {
    if (!isRunning) {
      throw Exception('VoiceIsolateManager: Isolate not running');
    }

    try {
      _isolateSendPort!.send({
        'command': 'dispatchIntent',
        'payload': payload.toJson(),
      });
      
      logger.info('VoiceIsolateManager: Dispatched intent: ${payload.intent}');
    } catch (e) {
      logger.error('VoiceIsolateManager: Failed to dispatch intent', e);
      rethrow;
    }
  }

  /// Send configuration to isolate
  Future<void> sendConfig(Map<String, dynamic> config) async {
    if (!isRunning) {
      throw Exception('VoiceIsolateManager: Isolate not running');
    }

    try {
      _isolateSendPort!.send({
        'command': 'updateConfig',
        'config': config,
      });
      
      logger.info('VoiceIsolateManager: Sent config to isolate');
    } catch (e) {
      logger.error('VoiceIsolateManager: Failed to send config', e);
      rethrow;
    }
  }

  /// Handle messages from the background isolate
  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      // First message is the isolate's SendPort
      _isolateSendPort = message;
      logger.info('VoiceIsolateManager: Received SendPort from isolate');
      
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      return;
    }

    if (message is Map) {
      final type = message['type'] as String?;
      
      switch (type) {
        case 'ready':
          logger.info('VoiceIsolateManager: Isolate is ready');
          break;
          
        case 'actionEvent':
          // Received action event from isolate
          final eventData = message['event'] as Map<String, dynamic>;
          final event = VoiceActionEvent.fromJson(eventData);
          eventBus.emit(AppEvent(AppEventType.voiceAction, event));
          
          onActionEvent?.call(event);
          break;
          
        case 'status':
          // Status update from isolate
          final status = message['status'] as String;
          final data = message['data'];
          onStatusUpdate?.call(status, data);
          logger.info('VoiceIsolateManager: Status - $status');
          break;
          
        case 'error':
          // Error from isolate
          final error = message['error'] as String;
          logger.error('VoiceIsolateManager: Isolate error - $error');
          break;
          
        default:
          logger.warning('VoiceIsolateManager: Unknown message type: $type');
      }
    }
  }

  /// Entry point for the background isolate
  static void _voiceIsolateEntryPoint(SendPort mainSendPort) {
    // Create receive port for this isolate
    final isolateReceivePort = ReceivePort();
    
    // Send this isolate's SendPort to main isolate
    mainSendPort.send(isolateReceivePort.sendPort);
    
    // Send ready signal
    mainSendPort.send({'type': 'ready'});

    // Create isolate worker
    final worker = _VoiceIsolateWorker(mainSendPort);

    // Listen for messages from main isolate
    isolateReceivePort.listen((message) {
    if (message is Map) {
      worker.handleCommand(Map<String, dynamic>.from(message));
    }
  });
  }
}

/// Worker class that runs in the background isolate
class _VoiceIsolateWorker {
  final SendPort _mainSendPort;
  
  // State and services will be initialized here
  Map<String, dynamic>? _config;
  
  _VoiceIsolateWorker(this._mainSendPort);

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

  void _handleDispatchIntent(Map<String, dynamic> message) {
    final payloadData = message['payload'] as Map<String, dynamic>;
    final payload = VoiceIntentPayload.fromJson(payloadData);

    _sendStatus('processing', {'intent': payload.intent});

    // Integrate with intent handlers (inline for isolate)
    var state = VoiceStateContext(currentScreen: 'idle');
    HandlerResult result;

    switch (payload.intent) {
      case 'selectBook':
        final bookName = payload.slots['bookName'] as String?;
        final bookId = bookName != null ? 'book_001' : null;
        state.currentBookId = bookId;
        state.currentScreen = 'bookSelected';
        result = HandlerResult(success: bookId != null, data: {'bookId': bookId ?? ''});
        break;
      case 'selectTopic':
        final topicName = payload.slots['topicName'] as String?;
        final topicId = topicName != null ? 'topic_001' : null;
        state.currentTopicId = topicId;
        state.currentScreen = 'topicSelected';
        result = HandlerResult(success: topicId != null, data: {'topicId': topicId ?? ''});
        break;
      case 'nextVocab':
        final currentIndex = state.currentCardIndex ?? 0;
        final nextIndex = currentIndex + 1;
        state.currentCardIndex = nextIndex;
        state.currentScreen = 'vocabCard';
        result = HandlerResult(success: true, data: {'cardIndex': nextIndex});
        break;
      case 'readAloud':
        final cardIndex = state.currentCardIndex ?? 0;
        result = HandlerResult(success: true, data: {'cardIndex': cardIndex});
        break;
      default:
        result = HandlerResult(success: false, data: {'intent': payload.intent, 'slots': payload.slots});
        break;
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