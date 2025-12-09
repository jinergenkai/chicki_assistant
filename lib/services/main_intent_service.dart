// import 'dart:async';
// import 'package:chicki_buddy/core/logger.dart';
// import 'package:chicki_buddy/services/unified_intent_handler.dart';
// import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'dart:convert';
// import 'package:get/get.dart';

// /// Service running in MAIN isolate to handle intents from foreground task
// /// This simplifies communication by handling ALL business logic here
// class MainIntentService {
//   static final MainIntentService _instance = MainIntentService._internal();
//   factory MainIntentService() => _instance;
//   MainIntentService._internal();

//   UnifiedIntentHandler? _handler;
//   void Function(Object)? _taskDataCallback;

//   bool _isInitialized = false;

//   /// Initialize the service and start listening to foreground task
//   Future<void> initialize() async {
//     if (_isInitialized) {
//       logger.warning('MainIntentService already initialized');
//       return;
//     }

//     try {
//       // Load workflow graph
//       final jsonStr = await rootBundle.loadString('assets/data/graph.json');
//       final graph = WorkflowGraph.fromJson(jsonDecode(jsonStr));

//       // Create unified intent handler
//       _handler = UnifiedIntentHandler(
//         workflowGraph: graph,
//         bookService: Get.find(),
//         vocabularyService: Get.find(),
//       );

//       // Listen to messages from foreground task
//       _taskDataCallback = (data) {
//         if (data is Map) {
//           _handleForegroundMessage(data as Map<String, dynamic>);
//         }
//       };

//       FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);

//       _isInitialized = true;
//       logger.success('MainIntentService initialized successfully');
//     } catch (e) {
//       logger.error('Failed to initialize MainIntentService', e);
//       rethrow;
//     }
//   }

//   /// Handle messages from foreground task
//   void _handleForegroundMessage(Map<String, dynamic> data) {
//     // Check if this is an intent request
//     if (data['type'] == 'intent_request' && data['intent'] != null) {
//       _handleIntentRequest(data);
//     }
//   }

//   /// Handle intent request from foreground
//   Future<void> _handleIntentRequest(Map<String, dynamic> request) async {
//     if (_handler == null) {
//       logger.error('Handler not initialized');
//       return;
//     }

//     try {
//       final intent = request['intent'] as String;
//       final slots = request['slots'] as Map<String, dynamic>? ?? {};

//       logger.info('MainIntentService: Processing intent: $intent');

//       // Handle intent using unified handler
//       final result = await _handler!.handleIntent(
//         intent: intent,
//         slots: slots,
//         source: IntentSource.speech, // From voice
//       );

//       logger
//           .success('MainIntentService: Intent processed: ${result['action']}');

//       // Send response back to foreground task
//       final response = {
//         'type': 'intent_response',
//         'result': result,
//       };

//       FlutterForegroundTask.sendDataToTask(response);
//     } catch (e) {
//       logger.error('Error handling intent request', e);

//       // Send error response
//       FlutterForegroundTask.sendDataToTask({
//         'type': 'intent_response',
//         'result': {
//           'action': 'error',
//           'text': 'Sorry, something went wrong: $e',
//         },
//       });
//     }
//   }

//   /// Dispose resources
//   void dispose() {
//     if (_taskDataCallback != null) {
//       FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
//       _taskDataCallback = null;
//     }
//     _isInitialized = false;
//     logger.info('MainIntentService disposed');
//   }
// }
