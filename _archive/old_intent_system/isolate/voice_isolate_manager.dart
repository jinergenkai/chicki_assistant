// Dart

import 'dart:async';
import 'dart:isolate';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/voice/models/voice_action_event.dart';
import 'package:chicki_buddy/voice/models/voice_intent_payload.dart';
import 'package:flutter/foundation.dart';
import '../../core/logger.dart';
import 'voice_isolate_entry.dart';
import 'voice_isolate_channel.dart';

/// Manages the background isolate for voice intent processing
class VoiceIsolateManager {
  static final VoiceIsolateManager _instance = VoiceIsolateManager._internal();
  factory VoiceIsolateManager() => _instance;
  VoiceIsolateManager._internal();

  Isolate? _isolate;
  ReceivePort? _mainReceivePort;
  final _readyCompleter = Completer<void>();
  VoiceIsolateChannel? _channel;

  Future<void> get ready => _readyCompleter.future;
  bool get isRunning => _isolate != null && _channel?.isolateSendPort != null;

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
      _mainReceivePort = ReceivePort();

      _channel = VoiceIsolateChannel(
        readyCompleter: _readyCompleter,
        onActionEvent: onActionEvent,
        onStatusUpdate: onStatusUpdate,
      );

      _isolate = await Isolate.spawn(
        voiceIsolateEntryPoint,
        _mainReceivePort!.sendPort,
        debugName: 'VoiceIntentIsolate',
      );

      _mainReceivePort!.listen(_channel!.handleMessage);

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
      if (_channel?.isolateSendPort != null) {
        _channel!.isolateSendPort!.send({'command': 'shutdown'});
      }
      await Future.delayed(const Duration(milliseconds: 100));
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _mainReceivePort?.close();
      _mainReceivePort = null;
      _channel = null;
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
      _channel!.isolateSendPort!.send({
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
      _channel!.isolateSendPort!.send({
        'command': 'updateConfig',
        'config': config,
      });
      logger.info('VoiceIsolateManager: Sent config to isolate');
    } catch (e) {
      logger.error('VoiceIsolateManager: Failed to send config', e);
      rethrow;
    }
  }
}