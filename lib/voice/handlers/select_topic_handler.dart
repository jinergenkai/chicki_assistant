import 'intent_handler.dart';
import '../models/voice_intent_payload.dart';
import '../models/voice_state_context.dart';

/// Handler for selectTopic intent
class SelectTopicHandler extends IntentHandler {
  @override
  String get name => 'findTopic';

  @override
  Future<HandlerResult> execute(
    VoiceIntentPayload payload,
    VoiceStateContext state,
  ) async {
    final topicName = payload.slots['topicName'] as String?;
    if (topicName == null) {
      return HandlerResult(success: false, data: {}, error: 'Missing topicName');
    }

    // Simulate topic lookup (replace with real lookup later)
    const topicId = 'topic1';

    state.currentTopicId = topicId;
    state.currentScreen = 'topicSelected';

    return HandlerResult(success: true, data: {'topicId': topicId});
  }
}