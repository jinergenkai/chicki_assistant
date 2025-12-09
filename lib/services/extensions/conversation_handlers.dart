import 'package:chicki_buddy/services/unified_intent_handler.dart';

/// Extension for conversation related intent handlers
extension ConversationHandlers on UnifiedIntentHandler {
  /// Handle start conversation intent
  Future<String> handleStartConversation() async {
    return 'Starting conversation mode. How can I help you?';
  }

  /// Handle stop conversation intent
  Future<String> handleStopConversation() async {
    return 'Stopping conversation mode';
  }
}
