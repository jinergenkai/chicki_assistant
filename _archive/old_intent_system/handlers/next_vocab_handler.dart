import 'intent_handler.dart';
import '../models/voice_intent_payload.dart';
import '../models/voice_state_context.dart';

/// Handler for nextVocab intent
class NextVocabHandler extends IntentHandler {
  @override
  String get name => 'incrementCardIndex';

  @override
  Future<HandlerResult> execute(
    VoiceIntentPayload payload,
    VoiceStateContext state,
  ) async {
    final currentIndex = state.currentCardIndex ?? 0;
    final nextIndex = currentIndex + 1;

    state.currentCardIndex = nextIndex;
    state.currentScreen = 'vocabCard';

    return HandlerResult(success: true, data: {'cardIndex': nextIndex});
  }
}