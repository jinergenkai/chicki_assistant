import 'package:chicki_buddy/core/logger.dart';

import 'intent_handler.dart';
import '../models/voice_intent_payload.dart';
import '../models/voice_state_context.dart';

/// Handler for selectBook intent
class SelectBookHandler extends IntentHandler {
  @override
  String get name => 'findBook';

  @override
  Future<HandlerResult> execute(
    VoiceIntentPayload payload,
    VoiceStateContext state,
  ) async {
    final bookName = payload.slots['bookName'] as String?;
    if (bookName == null) {
      return HandlerResult(success: false, data: {}, error: 'Missing bookName');
    }

    // Simulate book lookup (replace with real lookup later)
    const bookId = 'book1';

    state.currentBookId = bookId;
    state.currentScreen = 'bookSelected';

    logger.info('Handler - Selected book: $bookName with ID: $bookId');
    return HandlerResult(success: true, data: {'bookId': bookId});
  }
}