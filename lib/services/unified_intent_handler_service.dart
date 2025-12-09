import 'dart:async';
import 'dart:convert';
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

/// Permanent GetX Service that wraps UnifiedIntentHandler
/// Handles intent communication between foreground task and main isolate
class UnifiedIntentHandlerService extends GetxService {
  late UnifiedIntentHandler _handler;
  late BookService bookService;
  late VocabularyService vocabularyService;

  var isInitialized = false.obs;
  var currentNodeId = 'root'.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    logger.info('UnifiedIntentHandlerService: Initializing...');

    try {
      await _initializeServices();
      await _initializeIntentHandler();
      _startListeningToForeground();

      isInitialized.value = true;
      logger.success('UnifiedIntentHandlerService: Initialized successfully');
    } catch (e) {
      logger.error('UnifiedIntentHandlerService: Initialization failed', e);
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    logger.info('UnifiedIntentHandlerService: Initializing data services...');

    bookService = Get.find<BookService>();
    vocabularyService = Get.find<VocabularyService>();

    logger.success('UnifiedIntentHandlerService: Data services initialized');
  }

  Future<void> _initializeIntentHandler() async {
    logger.info('UnifiedIntentHandlerService: Loading workflow graph...');

    final jsonStr = await rootBundle.loadString('assets/data/graph.json');
    final graph = WorkflowGraph.fromJson(jsonDecode(jsonStr));

    _handler = UnifiedIntentHandler(
      workflowGraph: graph,
      bookService: bookService,
      vocabularyService: vocabularyService,
    );

    logger.success('UnifiedIntentHandlerService: Workflow graph loaded');
  }

  void _startListeningToForeground() {
    logger.info(
        'UnifiedIntentHandlerService: Started listening to foreground intents');
    FlutterForegroundTask.addTaskDataCallback(_handleForegroundMessage);
  }

  void _handleForegroundMessage(dynamic data) {
    if (data is! Map) return;

    final message = data as Map<String, dynamic>;

    // Only handle intent requests - ignore status updates (voiceState, micLifecycle, etc.)
    if (message['type'] == 'intent_request') {
      logger.info('🎯 Main: Handling intent request');
      _handleForegroundIntent(message);
    }
  }

  Future<void> _handleForegroundIntent(Map<String, dynamic> request) async {
    logger.info('🔵 Main: _handleForegroundIntent CALLED');
    logger.info('   Request: $request');

    try {
      final intent = request['intent'] as String;
      final slots = request['slots'] as Map<String, dynamic>? ?? {};

      logger.info('🔵 Main: Processing intent: $intent');
      logger.info('   Slots: $slots');

      // Process intent using UnifiedIntentHandler (returns String now)
      logger.info('🔄 Main: About to call handler.handleIntent...');

      final ttsText = await _handler.handleIntent(
        intent: intent,
        slots: slots,
      );

      logger.success('✅ Main: handler.handleIntent completed');
      logger.info('   Returned TTS: $ttsText');

      // Update observable state
      currentNodeId.value = _handler.currentNodeId;
      logger.info('   Updated currentNodeId: ${currentNodeId.value}');

      // Send TTS text back to foreground
      final response = {
        'type': 'intent_response',
        'ttsText': ttsText,
        'timestamp': DateTime.now().toIso8601String(),
      };

      logger.info('📤 Main: Preparing to send response...');
      logger.info('   Response data: $response');

      logger.info('📤 Main: Calling FlutterForegroundTask.sendDataToTask...');
      FlutterForegroundTask.sendDataToTask(response);

      logger
          .success('📤 Main: FlutterForegroundTask.sendDataToTask completed!');
      logger.success('📤 Main: Response sent successfully');
    } catch (e, stackTrace) {
      logger.error('❌ Main: ERROR in _handleForegroundIntent', e);
      logger.error('   Stack trace: $stackTrace');

      // Send error response
      final errorResponse = {
        'type': 'intent_response',
        'ttsText': 'Sorry, something went wrong: $e',
      };

      logger.info('📤 Main: Sending error response');
      try {
        FlutterForegroundTask.sendDataToTask(errorResponse);
        logger.info('📤 Main: Error response sent');
      } catch (sendError) {
        logger.error('❌ Main: Failed to send error response!', sendError);
      }
    }

    logger.info('🔵 Main: _handleForegroundIntent FINISHED');
  }

  /// Get available intents for current context
  List<String> getAvailableIntents() {
    return _handler.getAvailableIntents();
  }

  /// Get current handler state (for debugging)
  Map<String, dynamic> getCurrentState() {
    return _handler.getCurrentState();
  }

  @override
  void onClose() {
    FlutterForegroundTask.removeTaskDataCallback(_handleForegroundMessage);
    logger.info('UnifiedIntentHandlerService: Closed');
    super.onClose();
  }
}
