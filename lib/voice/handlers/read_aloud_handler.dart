import 'intent_handler.dart';
import '../models/voice_intent_payload.dart';
import '../models/voice_state_context.dart';

/// Handler for readAloud intent
class ReadAloudHandler extends IntentHandler {
  @override
  String get name => 'speakCurrentCard';

  @override
  Future<HandlerResult> execute(
    VoiceIntentPayload payload,
    VoiceStateContext state,
  ) async {
    // Simulate TTS action (replace with real TTS integration)
    final cardIndex = state.currentCardIndex ?? 0;

    // Normally, you would trigger TTS here
    return HandlerResult(success: true, data: {'cardIndex': cardIndex});
  }
}