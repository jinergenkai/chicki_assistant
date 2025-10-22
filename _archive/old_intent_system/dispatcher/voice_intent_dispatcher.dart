import '../models/voice_intent_payload.dart';
import '../models/voice_action_event.dart';
import '../models/voice_state_context.dart';
import 'package:chicki_buddy/services/book_service.dart';

/// Core dispatcher for processing intents and running the graph
class VoiceIntentDispatcher {
  VoiceStateContext _state = VoiceStateContext(currentScreen: 'idle');
  final BookService bookService = BookService();

  /// Process an incoming intent payload and return a VoiceActionEvent
  Future<VoiceActionEvent> dispatch(VoiceIntentPayload payload) async {
    // Xử lý intent đặc biệt cho book (ví dụ: listBook)
    if (payload.intent == 'listBook') {
      // Gọi BookService để lấy danh sách sách thật
      // (Chỉ dùng sync, nếu cần async thì phải refactor toàn bộ flow)
      await bookService.init();
      final books = await bookService.loadAllBooks();
      return VoiceActionEvent(
        action: 'listBook',
        data: {'books': books.map((b) => b.toJson()).toList()},
        requiresUI: false,
      );
    }
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
