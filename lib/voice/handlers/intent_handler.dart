import '../models/voice_intent_payload.dart';
import '../models/voice_state_context.dart';

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