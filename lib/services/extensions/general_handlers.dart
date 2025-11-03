import 'package:chicki_buddy/services/unified_intent_handler.dart';

/// Extension for general intent handlers
extension GeneralHandlers on UnifiedIntentHandler {
  /// Handle exit intent
  Future<Map<String, dynamic>> handleExit(IntentSource source) async {
    currentBookId = null;
    currentTopicId = null;
    currentCardIndex = null;

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Exited',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'exit',
        'data': {},
        'requiresUI': true,
      };
    }
  }

  /// Handle help intent
  Future<Map<String, dynamic>> handleHelp(IntentSource source) async {
    final availableIntents = getAvailableIntents();

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Available commands: ${availableIntents.join(', ')}',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'help',
        'data': {'availableIntents': availableIntents},
        'requiresUI': true,
      };
    }
  }
}
