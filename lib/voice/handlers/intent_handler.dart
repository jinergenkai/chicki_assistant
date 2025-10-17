import '../models/voice_intent_payload.dart';
import '../models/voice_state_context.dart';

export 'next_vocab_handler.dart';
export 'read_aloud_handler.dart';
export 'select_book_handler.dart';
export 'select_topic_handler.dart';

/// Base interface for intent handlers
abstract class IntentHandler {
  String get name;
  Future<HandlerResult> execute(
    VoiceIntentPayload payload,
    VoiceStateContext state,
  );
}

/// Result of handler execution
class HandlerResult {
  final bool success;
  final Map<String, dynamic> data;
  final String? error;

  HandlerResult({
    required this.success,
    required this.data,
    this.error,
  });
}
