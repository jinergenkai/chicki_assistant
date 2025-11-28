import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/core/isolate_message.dart';
import 'package:chicki_buddy/services/llm_intent_classifier_service.dart';
import 'package:chicki_buddy/services/notification_manager.dart';
import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../core/logger.dart';
import '../core/app_event_bus.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/local_llm_service.dart';
import '../services/llm_service.dart';

enum VoiceState { uninitialized, needsPermission, idle, listening, processing, speaking, detecting, error }

class VoiceForegroundTaskHandler extends TaskHandler {
  // Note: Cannot use Get.find() in isolate, instantiate directly if needed
  final STTService _sttService = SpeechToTextService();
  final TTSService _ttsService = TextToSpeechService();
  // final TTSService _ttsService = SherpaTtsService();
  // final LLMService _gptService = LocalLLMService();
  final LLMIntentClassifierService _intentClassifier = LLMIntentClassifierService();

  final fgReceivePort = ReceivePort();
  
  // Store pending intent response
  Completer<Map<String, dynamic>>? _pendingIntentResponse;

  SendPort? bgPort;

  StreamSubscription? _wakewordSub;
  bool _isInitialized = false;
  
  // Test timer for offscreen capability verification
  Timer? _testTimer;

  VoiceState state = VoiceState.uninitialized;
  String recognizedText = '';
  String gptResponse = '';
  double rmsDB = 2.0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();

    await initHive();

    // Communication is done via FlutterForegroundTask.sendDataToMain
    await initialize();
    _setupSTTListener();
    _setupRmsListener();
    
    // Start test timer for offscreen verification
    // _startTestTimer();
  }

  Future<void> initHive() async {
    // No longer needed - Hive is only in main isolate now
    // Keep method for compatibility but do nothing
    logger.info('ForegroundTask: Skipping Hive init (handled by main isolate)');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic event - send status update
    // _sendMessage(IsolateMessage.status('running', extra: {'state': state.name}));
  }

  /// Helper to send unified messages
  void _sendMessage(IsolateMessage message) {
    FlutterForegroundTask.sendDataToMain(message.toMap());
  }

  @override
  Future<void> onReceiveData(Object data) async {
    if (data is! Map) return;

    // Parse message using unified format
    final message = IsolateMessage.fromMap(data as Map<String, dynamic>);
    logger.info('ForegroundTask: Received message: ${message.type.name}');

    await _handleMessage(message);
  }

  Future<void> _handleMessage(IsolateMessage message) async {
    // Handle test response from main isolate
    if (message.data['type'] == 'test_response') {
      _handleTestResponse(message.data);
      return;
    }
    
    // Handle intent response from main isolate (NEW)
    if (message.data['type'] == 'intent_response') {
      _handleIntentResponse(message.data);
      return;
    }
    
    switch (message.type) {
      case MessageType.intent:
        await _handleIntentMessage(message);
        break;

      case MessageType.command:
        await _handleCommandMessage(message);
        break;

      case MessageType.config:
        await _handleConfigMessage(message);
        break;

      case MessageType.wakeword:
        await _handleWakewordMessage(message);
        break;

      default:
        logger.warning('ForegroundTask: Unhandled message type: ${message.type.name}');
    }
  }
  
  void _handleTestResponse(Map<String, dynamic> response) {
    final data = response['data'];
    logger.success('🟢 Foreground: Received test response from main isolate');
    logger.info('   Message: ${data['message']}');
    logger.info('   Total Requests: ${data['totalRequests']}');
    logger.info('   Service Active: ${data['serviceActive']}');
  }

  Future<void> _handleIntentMessage(IsolateMessage message) async {
    // This is now handled by sending to main isolate
    // Keep for backward compatibility but delegate to main
    final intent = message.data['intent'] as String?;
    if (intent == null) return;

    final slots = message.data['slots'] as Map<String, dynamic>? ?? {};
    
    // Send to main isolate for processing
    await _sendIntentToMain(intent, slots);
  }
  
  /// Handle intent response from main isolate
  void _handleIntentResponse(Map<String, dynamic> response) {
    final result = response['result'] as Map<String, dynamic>;
    logger.success('🟢 Foreground: Received intent response from main');
    logger.info('   Action: ${result['action']}');
    
    // Complete pending response if exists
    if (_pendingIntentResponse != null && !_pendingIntentResponse!.isCompleted) {
      _pendingIntentResponse!.complete(result);
      _pendingIntentResponse = null;
    }
    
    // Send result to main isolate (for UI updates)
    _sendMessage(IsolateMessage.intentResult(result));
  }
  
  /// Send intent to main isolate for processing
  Future<Map<String, dynamic>> _sendIntentToMain(String intent, Map<String, dynamic> slots) async {
    logger.info('📤 Foreground: Sending intent to main: $intent');
    
    _pendingIntentResponse = Completer<Map<String, dynamic>>();
    
    final request = {
      'type': 'intent_request',
      'intent': intent,
      'slots': slots,
      'source': 'speech',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    FlutterForegroundTask.sendDataToMain(request);
    
    // Wait for response with timeout
    try {
      final result = await _pendingIntentResponse!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.error('Timeout waiting for intent response from main');
          return {
            'action': 'error',
            'error': 'Timeout waiting for response',
          };
        },
      );
      return result;
    } catch (e) {
      logger.error('Error waiting for intent response', e);
      return {
        'action': 'error',
        'error': e.toString(),
      };
    }
  }

  Future<void> _handleCommandMessage(IsolateMessage message) async {
    final command = message.data['command'] as String?;
    if (command == null) return;

    switch (command) {
      case 'startListening':
      case 'start_listening':
        _sendMessage(IsolateMessage.status('listening'));
        await startListening();
        break;

      case 'stopListening':
      case 'stop_listening':
        await stopListening();
        break;

      case 'stopSpeaking':
      case 'stop_speaking':
        await stopSpeaking();
        break;

      case 'stop_detecting':
        // Pause wakeword detection
        state = VoiceState.idle;
        NotificationManager.updateForState(state);
        break;

      case 'retry':
        // Retry after error
        state = VoiceState.idle;
        NotificationManager.updateForState(state);
        break;

      case 'cancel':
        // Cancel current operation
        await stopListening();
        await stopSpeaking();
        break;

      case 'open_app':
        // This will be handled by the main app
        logger.info('Open app requested from notification');
        break;

      default:
        logger.warning('ForegroundTask: Unknown command: $command');
    }
  }

  Future<void> _handleConfigMessage(IsolateMessage message) async {
    final config = AppConfigController.fromJson(message.data['config']);
    SpeechToTextService().setConfig(config);
    TextToSpeechService().setConfig(config);
    LocalLLMService().setConfig(config);
    _sendMessage(IsolateMessage.status('config_set'));
  }

  Future<void> _handleWakewordMessage(IsolateMessage message) async {
    logger.info('ForegroundTask: Wakeword detected from main isolate');
    if (state == VoiceState.idle) {
      await startListening();
    }
  }

  Future<void> initialize() async {
    try {
      state = VoiceState.uninitialized;
      NotificationManager.updateForState(state);
      _sendMessage(IsolateMessage.voiceState(state.name));

      await PermissionUtils.checkMicrophone();
      state = VoiceState.needsPermission;
      NotificationManager.updateForState(state);
      _sendMessage(IsolateMessage.voiceState(state.name));

      await _sttService.initialize();
      await _ttsService.initialize();

      _isInitialized = true;
      logger.info('VoiceForegroundTaskHandler initialized successfully');
      state = VoiceState.idle;
      NotificationManager.updateForState(state);
      _sendMessage(IsolateMessage.voiceState(state.name));
    } catch (e) {
      logger.error('Failed to initialize VoiceForegroundTaskHandler', e);
      state = VoiceState.error;
      NotificationManager.updateForState(state, additionalInfo: e.toString());
      _sendMessage(IsolateMessage.voiceState(state.name, error: e.toString()));
      rethrow;
    }
  }

  void _setupSTTListener() {
    _sttService.onTextRecognized.listen((text) async {
      if (text.isNotEmpty) {
        try {
          recognizedText = text;
          NotificationManager.showRecognizedText(text);
          _sendMessage(IsolateMessage.recognizedText(text));

          // STT finished, mic stopped
          _sendMessage(IsolateMessage.micLifecycle('stopped'));
          logger.info('ForegroundTask: STT finished, sent micStopped to main isolate');

          state = VoiceState.processing;
          NotificationManager.updateForState(state, additionalInfo: text);
          _sendMessage(IsolateMessage.voiceState(state.name));
          logger.info('Processing speech input: $text');

          // Classify intent using LLM
          final response = await _intentClassifier.classify(text);
          logger.success('LLM intent result: $response');

          // Send intent to main isolate for processing (NEW ARCHITECTURE)
          String textToSpeak = response['intent'];
          String? intentName = response['intent'];

          if (response['intent'] != null) {
            final result = await _sendIntentToMain(
              response['intent'] as String,
              response['slots'] is Map ? Map<String, dynamic>.from(response['slots']) : {},
            );

            logger.success('Intent processed by main isolate');
            
            // Use TTS text if available, otherwise use intent name
            if (result['action'] == 'speak' && result['text'] != null) {
              textToSpeak = result['text'];
            }
          }

          state = VoiceState.speaking;
          NotificationManager.updateForState(state, additionalInfo: textToSpeak);
          _sendMessage(IsolateMessage.voiceState(state.name));
          await _ttsService.speak(textToSpeak);

          // Show result in notification
          if (intentName != null) {
            NotificationManager.showIntentResult(intentName, textToSpeak);
          }

          state = VoiceState.idle;
          NotificationManager.updateForState(state);
          _sendMessage(IsolateMessage.voiceState(state.name));
        } catch (e) {
          logger.error('Error processing voice input', e);
          state = VoiceState.error;
          NotificationManager.updateForState(state, additionalInfo: e.toString());
          _sendMessage(IsolateMessage.voiceState(state.name, error: e.toString()));
        }
      }
    });
  }

  void _setupRmsListener() {
    _sttService.onRmsChanged.listen((level) {
      rmsDB = level;
      _sendMessage(IsolateMessage.rmsLevel(level));

      // Update notification with audio level visualization when listening
      if (state == VoiceState.listening) {
        NotificationManager.showListeningWithLevel(level);
      }
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('VoiceForegroundTaskHandler not initialized');
    }
    try {
      final hasPermission = await PermissionUtils.checkMicrophone();
      if (!hasPermission) {
        state = VoiceState.needsPermission;
        NotificationManager.updateForState(state);
        _sendMessage(IsolateMessage.voiceState(state.name));
        return;
      }

      // Send micStarted to pause wakeword
      _sendMessage(IsolateMessage.micLifecycle('started'));
      logger.info('ForegroundTask: Sent micStarted to main isolate');

      await _sttService.startListening();
      state = VoiceState.listening;
      NotificationManager.updateForState(state);
      _sendMessage(IsolateMessage.voiceState(state.name));
      logger.info('VoiceForegroundTaskHandler: Started listening');
    } catch (e) {
      logger.error('Error starting voice listening', e);
      state = VoiceState.error;
      NotificationManager.updateForState(state, additionalInfo: e.toString());
      _sendMessage(IsolateMessage.voiceState(state.name, error: e.toString()));
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      await _sttService.stopListening();

      // Send micStopped to resume wakeword
      _sendMessage(IsolateMessage.micLifecycle('stopped'));
      logger.info('ForegroundTask: Sent micStopped to main isolate');

      state = VoiceState.idle;
      NotificationManager.updateForState(state);
      _sendMessage(IsolateMessage.voiceState(state.name));
      logger.info('VoiceForegroundTaskHandler: Stopped listening');
    } catch (e) {
      logger.error('Error stopping voice listening', e);
      // Still send micStopped to ensure wakeword resumes
      _sendMessage(IsolateMessage.micLifecycle('stopped'));
      state = VoiceState.error;
      NotificationManager.updateForState(state, additionalInfo: e.toString());
      _sendMessage(IsolateMessage.voiceState(state.name, error: e.toString()));
      rethrow;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _ttsService.stop();
      state = VoiceState.idle;
      NotificationManager.updateForState(state);
      _sendMessage(IsolateMessage.voiceState(state.name));
      logger.info('Stopped speaking');
    } catch (e) {
      logger.error('Error stopping speech', e);
      state = VoiceState.error;
      NotificationManager.updateForState(state, additionalInfo: e.toString());
      _sendMessage(IsolateMessage.voiceState(state.name, error: e.toString()));
      rethrow;
    }
  }

  @override
  Future<void> onNotificationButtonPressed(String id) async {
    logger.info('ForegroundTask: Notification button pressed: $id');

    // Handle notification button clicks
    final message = IsolateMessage.command(id);
    await _handleCommandMessage(message);
  }

  void _startTestTimer() {
    logger.info('🔴 Foreground: Starting test timer (every 5 seconds)');
    _testTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendTestRequest();
    });
  }
  
  void _sendTestRequest() {
    final request = {
      'type': 'test_request',
      'action': 'periodic_test',
      'timestamp': DateTime.now().toIso8601String(),
      'requestId': DateTime.now().millisecondsSinceEpoch,
    };
    
    FlutterForegroundTask.sendDataToMain(request);
    logger.info('🔴 Foreground: Sent test request #${DateTime.now().millisecondsSinceEpoch} to main isolate');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _testTimer?.cancel();
    await stopListening();
    await stopSpeaking();
    _wakewordSub?.cancel();
    _sendMessage(IsolateMessage.status('destroyed'));
    logger.info('ForegroundTask: Destroyed and cleaned up');
  }
}
