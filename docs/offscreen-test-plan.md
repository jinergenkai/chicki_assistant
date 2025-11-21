# Offscreen Data Access Test Plan

## 🎯 Objective
Verify that a permanent GetX Service can receive and process requests from foreground isolate when app is offscreen.

## 📋 Current Architecture Issue

**Problem:**
```
UI → Foreground Isolate → Hive (foreground) → Foreground → Main → UI
```
- Too complex
- Duplicate Hive instances
- Voice and UI cannot share data access easily

**Proposed Solution (Option D - Reverse Bridge):**
```
Voice Foreground → Event → Main (GetX Service) → Hive → Event → Foreground → TTS
UI → Main (GetX Service) → Hive → UI
```

## 🧪 Test Implementation

### 1. Test Service (CREATED)
**File:** `lib/services/test_data_service.dart`
- ✅ Created permanent GetX Service
- ✅ Listens to foreground requests via `FlutterForegroundTask.addTaskDataCallback`
- ✅ Tracks request count and timestamps
- ✅ Sends responses back to foreground

**Key Features:**
- Permanent service (never disposed)
- Request/response logging
- Counter to track activity when offscreen
- UI trigger capability for testing

### 2. Register Service in Main
**File:** `lib/main.dart`
**Changes needed:**
```dart
// Add import
import 'package:chicki_buddy/services/test_data_service.dart';

// In main() function, add:
Get.put(TestDataService(), permanent: true);
```

### 3. Add Foreground Test Trigger
**File:** `lib/services/voice_foreground_task_handler.dart`
**Changes needed:**

```dart
// Add periodic test trigger
Timer? _testTimer;

@override
Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
  // ... existing code ...
  
  // Start test timer (every 5 seconds)
  _startTestTimer();
}

void _startTestTimer() {
  _testTimer = Timer.periodic(Duration(seconds: 5), (timer) {
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
  logger.info('🔴 Foreground: Sent test request to main isolate');
}

// Handle test response
Future<void> _handleMessage(IsolateMessage message) async {
  // ... existing code ...
  
  // Add test response handler
  if (message.data['type'] == 'test_response') {
    final data = message.data['data'];
    logger.success('🟢 Foreground: Received test response from main');
    logger.info('   Message: ${data['message']}');
    logger.info('   Total Requests: ${data['totalRequests']}');
  }
}

@override
Future<void> onDestroy(DateTime timestamp) async {
  _testTimer?.cancel();
  // ... existing code ...
}
```

### 4. Add Debug UI
**File:** `lib/ui/screens/debug_screen.dart`
**Changes needed:**

Add test widget:
```dart
// In debug screen
Obx(() {
  final testService = Get.find<TestDataService>();
  return Column(
    children: [
      Text('Test Service Status'),
      Text('Requests: ${testService.requestCount.value}'),
      Text('Last: ${testService.lastRequestTime.value}'),
      ElevatedButton(
        onPressed: () => testService.triggerTestFromUI(),
        child: Text('Trigger Test'),
      ),
      ElevatedButton(
        onPressed: () => testService.reset(),
        child: Text('Reset'),
      ),
      // Recent responses
      ...testService.responses.map((r) => Text(r)),
    ],
  );
})
```

## 🔬 Test Procedure

### Phase 1: Service Registration Test
1. ✅ Create TestDataService
2. Register in main.dart
3. Run app and verify service initializes
4. Check logs: "TestDataService initialized - This service is PERMANENT"

### Phase 2: UI → Service Test
1. Add debug UI button
2. Tap button to trigger test
3. Verify service receives and logs request
4. Check counter increments

### Phase 3: Foreground → Service Test (ONSCREEN)
1. Add periodic test in foreground
2. Start foreground service
3. Verify requests sent every 5s
4. Check logs show request/response cycle
5. Monitor counter in debug UI

### Phase 4: Offscreen Test (CRITICAL)
1. Start foreground service
2. Minimize app (home button)
3. Wait 30 seconds
4. Open app again
5. Check debug UI counter - should show ~6 requests
6. Verify logs show continuous operation

### Phase 5: Extended Offscreen Test
1. Start foreground service
2. Minimize app for 5 minutes
3. Return to app
4. Verify ~60 requests processed
5. Check no gaps in timestamps

## 📊 Expected Results

### Success Criteria:
- ✅ Service receives requests when app offscreen
- ✅ Request count continues to increment
- ✅ No gaps in timestamp log
- ✅ Response latency < 200ms
- ✅ No Android system killing the service

### Performance Metrics:
- Request processing time: < 100ms
- Response time: < 200ms
- Memory impact: < 10MB
- Battery impact: Minimal (passive listener)

## 🚨 Potential Issues

### Issue 1: Service Gets Killed
**Symptom:** Counter stops incrementing when offscreen
**Solution:** Ensure `permanent: true` in Get.put()

### Issue 2: Callback Not Triggered
**Symptom:** No logs when offscreen
**Solution:** Verify `FlutterForegroundTask.addTaskDataCallback` is called in onInit

### Issue 3: Response Not Received
**Symptom:** Request sent but no response in foreground
**Solution:** Check foreground's onReceiveData handles 'test_response' type

## 📝 Implementation Files

### New Files:
1. ✅ `lib/services/test_data_service.dart` - Test service (CREATED)
2. `docs/offscreen-test-plan.md` - This document

### Modified Files:
1. `lib/main.dart` - Register test service
2. `lib/services/voice_foreground_task_handler.dart` - Add test trigger
3. `lib/ui/screens/debug_screen.dart` - Add test UI

## 🎬 Next Steps

1. Switch to Code mode
2. Implement remaining changes:
   - Register service in main.dart
   - Add foreground test trigger
   - Add debug UI
3. Run test procedure
4. Document results
5. If successful → Implement real data access service

## 💡 Conclusion

This test will prove that:
- ✅ GetX Service can be permanent and active offscreen
- ✅ Foreground isolate can communicate with main isolate bidirectionally
- ✅ Option D (Reverse Bridge Pattern) is viable
- ✅ No need for duplicate Hive instances in foreground
- ✅ Single source of truth architecture is achievable

If test succeeds → Refactor entire data access layer to use this pattern.