import 'package:chicki_buddy/services/unified_intent_handler.dart';

/// Extension for conversation related intent handlers
extension ConversationHandlers on UnifiedIntentHandler {
  /// Handle start conversation intent
  Future<Map<String, dynamic>> handleStartConversation(IntentSource source) async {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Starting conversation mode. How can I help you?',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'startConversation',
        'data': {},
        'requiresUI': true,
      };
    }
  }

  /// Handle stop conversation intent
  Future<Map<String, dynamic>> handleStopConversation(IntentSource source) async {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Conversation ended',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'stopConversation',
        'data': {},
        'requiresUI': true,
      };
    }
  }
}
