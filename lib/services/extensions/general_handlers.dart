import 'package:chicki_buddy/services/unified_intent_handler.dart';

/// Extension for general intent handlers
extension GeneralHandlers on UnifiedIntentHandler {
  /// Handle help intent
  Future<String> handleHelp() async {
    final availableIntents = getAvailableIntents();
    return 'Available commands: ${availableIntents.join(', ')}';
  }

  /// Handle exit intent
  Future<String> handleExit() async {
    resetContext();
    return 'Exiting to home';
  }
}
