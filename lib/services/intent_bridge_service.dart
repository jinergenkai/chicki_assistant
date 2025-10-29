import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:chicki_buddy/core/isolate_message.dart';
import 'package:chicki_buddy/core/logger.dart';

/// Bridge service to communicate with foreground task for intent handling
/// This allows UI controllers to trigger intents that run in foreground isolate
class IntentBridgeService {
  
  /// Trigger an intent from UI (runs in foreground isolate)
  static void triggerUIIntent({
    required String intent,
    Map<String, dynamic>? slots,
  }) async {
    logger.info('Triggering UI intent: $intent with slots: $slots');
    
    final message = IsolateMessage.intent(
      intent: intent,
      slots: slots,
      source: MessageSource.ui,
    );
    
    FlutterForegroundTask.sendDataToTask(message.toMap());
  }
  
  /// Trigger a speech intent (already handled in VoiceForegroundTaskHandler)
  /// This is just for documentation - speech intents are handled automatically
  static Future<void> triggerSpeechIntent({
    required String intent,
    Map<String, dynamic>? slots,
  }) async {
    logger.info('Triggering speech intent: $intent with slots: $slots');
    
    final message = IsolateMessage.intent(
      intent: intent,
      slots: slots,
      source: MessageSource.speech,
    );
    
    FlutterForegroundTask.sendDataToTask(message.toMap());
  }
}