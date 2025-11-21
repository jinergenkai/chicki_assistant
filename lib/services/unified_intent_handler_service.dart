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
/// Lives in main isolate and handles both UI and voice intents
/// Voice intents come from foreground isolate via FlutterForegroundTask
class UnifiedIntentHandlerService extends GetxService {
  late UnifiedIntentHandler _handler;
  late BookService bookService;
  late VocabularyService vocabularyService;
  
  var isInitialized = false.obs;
  var currentNodeId = 'root'.obs;
  var currentBookId = Rxn<String>();
  var currentTopicId = Rxn<String>();
  var currentCardIndex = Rxn<int>();

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

  /// Initialize BookService and VocabularyService
  Future<void> _initializeServices() async {
    logger.info('UnifiedIntentHandlerService: Initializing data services...');
    
    bookService = BookService();
    vocabularyService = VocabularyService();
    
    await bookService.init();
    await vocabularyService.init();
    
    logger.success('UnifiedIntentHandlerService: Data services initialized');
  }

  /// Initialize UnifiedIntentHandler with workflow graph
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

  /// Start listening to intent requests from foreground isolate
  void _startListeningToForeground() {
    logger.info('UnifiedIntentHandlerService: Started listening to foreground intents');
    FlutterForegroundTask.addTaskDataCallback(_handleForegroundMessage);
  }

  /// Handle messages from foreground isolate
  void _handleForegroundMessage(dynamic data) {
    if (data is! Map) return;
    
    final message = data as Map<String, dynamic>;
    
    // Handle intent requests from foreground (voice)
    if (message['type'] == 'intent_request') {
      _handleForegroundIntent(message);
    }
  }

  /// Handle intent request from foreground isolate
  Future<void> _handleForegroundIntent(Map<String, dynamic> request) async {
    try {
      final intent = request['intent'] as String;
      final slots = request['slots'] as Map<String, dynamic>? ?? {};
      final source = request['source'] == 'speech' 
          ? IntentSource.speech 
          : IntentSource.ui;
      
      logger.info('🔵 Main: Received intent from foreground: $intent');
      logger.info('   Slots: $slots, Source: ${source.name}');
      
      // Process intent using UnifiedIntentHandler
      final result = await handleIntent(
        intent: intent,
        slots: slots,
        source: source,
      );
      
      logger.success('✅ Main: Intent processed successfully');
      logger.info('   Result action: ${result['action']}');
      
      // Send response back to foreground
      final response = {
        'type': 'intent_response',
        'intent': intent,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      FlutterForegroundTask.sendDataToTask(response);
      logger.info('📤 Main: Response sent to foreground');
      
    } catch (e) {
      logger.error('❌ Main: Error handling foreground intent', e);
      
      // Send error response
      final errorResponse = {
        'type': 'intent_response',
        'intent': request['intent'],
        'result': {
          'action': 'error',
          'error': e.toString(),
        },
      };
      
      FlutterForegroundTask.sendDataToTask(errorResponse);
    }
  }

  /// Main entry point for handling intents (both UI and voice)
  /// UI controllers call this directly
  /// Voice intents come via _handleForegroundIntent
  Future<Map<String, dynamic>> handleIntent({
    required String intent,
    Map<String, dynamic>? slots,
    required IntentSource source,
  }) async {
    if (!isInitialized.value) {
      logger.warning('UnifiedIntentHandlerService: Not initialized yet');
      return {
        'action': 'error',
        'error': 'Service not initialized',
      };
    }

    try {
      // Delegate to UnifiedIntentHandler
      final result = await _handler.handleIntent(
        intent: intent,
        slots: slots,
        source: source,
      );
      
      // Update observable state
      _updateState();
      
      return result;
    } catch (e) {
      logger.error('UnifiedIntentHandlerService: Error handling intent', e);
      return {
        'action': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Update reactive state from handler
  void _updateState() {
    currentNodeId.value = _handler.currentNodeId;
    currentBookId.value = _handler.currentBookId;
    currentTopicId.value = _handler.currentTopicId;
    currentCardIndex.value = _handler.currentCardIndex;
  }

  /// Reset context to root
  void resetContext([String? nodeId]) {
    _handler.resetContext(nodeId);
    _updateState();
    logger.info('UnifiedIntentHandlerService: Context reset to ${currentNodeId.value}');
  }

  /// Get available intents for current context
  List<String> getAvailableIntents() {
    return _handler.getAvailableIntents();
  }

  /// Get current handler state (for debugging)
  Map<String, dynamic> getCurrentState() {
    return _handler.getCurrentState();
  }

  /// Sync flash card context (from UI)
  Future<void> syncFlashCardContext(String bookId) async {
    await handleIntent(
      intent: 'syncFlashCardContext',
      slots: {'bookId': bookId},
      source: IntentSource.ui,
    );
  }

  /// Exit flash card context
  Future<void> exitFlashCardContext() async {
    await handleIntent(
      intent: 'exitFlashCard',
      slots: {},
      source: IntentSource.ui,
    );
  }

  @override
  void onClose() {
    FlutterForegroundTask.removeTaskDataCallback(_handleForegroundMessage);
    logger.info('UnifiedIntentHandlerService: Closed');
    super.onClose();
  }
}