import 'dart:async';
import 'package:chicki_buddy/core/logger.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

/// Test service to verify offscreen data access capability
/// This service is PERMANENT and stays alive even when app is offscreen
class TestDataService extends GetxService {
  var requestCount = 0.obs;
  var lastRequestTime = DateTime.now().obs;
  var isListening = false.obs;
  
  final _responses = <String>[].obs;
  List<String> get responses => _responses;

  @override
  void onInit() {
    super.onInit();
    logger.success('TestDataService initialized - This service is PERMANENT');
    _startListening();
  }

  void _startListening() {
    isListening.value = true;
    logger.info('TestDataService: Started listening to foreground requests');
    
    // Listen to messages from foreground isolate
    FlutterForegroundTask.addTaskDataCallback(_handleForegroundMessage);
  }

  void _handleForegroundMessage(dynamic data) {
    if (data is! Map) return;
    
    final message = data as Map<String, dynamic>;
    
    // Only handle test requests
    if (message['type'] == 'test_request') {
      _handleTestRequest(message);
    }
  }

  Future<void> _handleTestRequest(Map<String, dynamic> request) async {
    requestCount.value++;
    lastRequestTime.value = DateTime.now();
    
    final action = request['action'] as String?;
    final timestamp = request['timestamp'] as String?;
    
    logger.success('🎯 TestDataService: Received request #${requestCount.value} - Action: $action');
    logger.info('   Time: $timestamp');
    logger.info('   App State: ${Get.currentRoute.isEmpty ? "OFFSCREEN" : "ONSCREEN"}');
    
    // Simulate some work
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Prepare response
    final response = {
      'type': 'test_response',
      'action': action,
      'requestId': request['requestId'],
      'result': 'success',
      'data': {
        'message': 'Data from main isolate #${requestCount.value}',
        'timestamp': DateTime.now().toIso8601String(),
        'serviceActive': true,
        'totalRequests': requestCount.value,
      }
    };
    
    // Send response back to foreground isolate
    FlutterForegroundTask.sendDataToTask(response);
    
    _responses.add('Request #${requestCount.value} at ${DateTime.now().toString().split('.')[0]}');
    if (_responses.length > 10) {
      _responses.removeAt(0); // Keep only last 10
    }
    
    logger.success('✅ TestDataService: Response sent back to foreground');
  }

  /// Manually trigger a test from UI
  void triggerTestFromUI() {
    logger.info('🔵 TestDataService: UI triggered test');
    
    final request = {
      'type': 'test_request',
      'action': 'ui_test',
      'timestamp': DateTime.now().toIso8601String(),
      'requestId': DateTime.now().millisecondsSinceEpoch,
    };
    
    _handleTestRequest(request);
  }

  void reset() {
    requestCount.value = 0;
    _responses.clear();
    logger.info('TestDataService: Reset counters');
  }

  @override
  void onClose() {
    FlutterForegroundTask.removeTaskDataCallback(_handleForegroundMessage);
    isListening.value = false;
    super.onClose();
  }
}