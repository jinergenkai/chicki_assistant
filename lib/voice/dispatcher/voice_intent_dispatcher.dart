import '../models/voice_intent_payload.dart';
import '../models/voice_action_event.dart';
import '../models/voice_state_context.dart';

/// Core dispatcher for processing intents and running the graph
class VoiceIntentDispatcher {
  VoiceStateContext _state = VoiceStateContext(currentScreen: 'idle');

  /// Process an incoming intent payload and return a VoiceActionEvent
  VoiceActionEvent dispatch(VoiceIntentPayload payload) {
    // Example: basic graph logic (replace with full graph runner later)
    switch (_state.currentScreen) {
      case 'idle':
        if (payload.intent == 'selectBook' && payload.slots['bookName'] != null) {
          _state.currentBookId = 'book_001'; // Simulate lookup
          _state.currentScreen = 'bookSelected';
          return VoiceActionEvent(
            action: 'navigateToBook',
            data: {'bookId': _state.currentBookId},
            requiresUI: true,
          );
        }
        break;
      case 'bookSelected':
        if (payload.intent == 'selectTopic' && payload.slots['topicName'] != null) {
          _state.currentTopicId = 'topic_001'; // Simulate lookup
          _state.currentScreen = 'topicSelected';
          return VoiceActionEvent(
            action: 'navigateToTopic',
            data: {'topicId': _state.currentTopicId},
            requiresUI: true,
          );
        }
        break;
      case 'topicSelected':
        if (payload.intent == 'nextVocab') {
          _state.currentCardIndex = (_state.currentCardIndex ?? 0) + 1;
          _state.currentScreen = 'vocabCard';
          return VoiceActionEvent(
            action: 'showCard',
            data: {'cardIndex': _state.currentCardIndex},
            requiresUI: true,
          );
        }
        if (payload.intent == 'readAloud') {
          return VoiceActionEvent(
            action: 'readAloud',
            data: {'cardIndex': _state.currentCardIndex},
            requiresUI: true,
          );
        }
        break;
      case 'vocabCard':
        if (payload.intent == 'nextVocab') {
          _state.currentCardIndex = (_state.currentCardIndex ?? 0) + 1;
          return VoiceActionEvent(
            action: 'showCard',
            data: {'cardIndex': _state.currentCardIndex},
            requiresUI: true,
          );
        }
        if (payload.intent == 'readAloud') {
          return VoiceActionEvent(
            action: 'readAloud',
            data: {'cardIndex': _state.currentCardIndex},
            requiresUI: true,
          );
        }
        break;
      default:
        break;
    }
    // Fallback: unknown intent or transition
    return VoiceActionEvent(
      action: 'unknownIntent',
      data: {'intent': payload.intent, 'slots': payload.slots},
      requiresUI: false,
    );
  }

  /// Reset dispatcher state (for testing)
  void reset() {
    _state = VoiceStateContext(currentScreen: 'idle');
  }

  /// Get current state (for debugging)
  VoiceStateContext get state => _state;
}