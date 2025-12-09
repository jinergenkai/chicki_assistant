import 'package:chicki_buddy/voice/dispatcher/intent_classifier_service.dart';

import 'package:chicki_buddy/network/llm.api.dart';
import 'dart:convert';

class LLMIntentClassifierService extends IntentClassifierService {
  final LlmApi _llmApi = LlmApi();

  // Core intents: flashcard control + book selection + conversation
  static const _intentList = [
    'listBook', // List available books
    'selectBook', // Open a book for flashcard learning
    'nextCard', // Navigate to next card
    'prevCard', // Navigate to previous card
    'flipCard', // Flip current card to see meaning/details
    'bookmarkWord', // Bookmark current word
    'startConversation', // Start conversation mode
  ];

  @override
  Future<Map<String, dynamic>> classify(String text) async {
    final prompt = _buildPrompt(text);
    final response = await _llmApi.chat(systemPrompt: prompt, prompt: text);

    // Parse response dạng JSON
    try {
      final result = json.decode(response);
      if (result is Map<String, dynamic> && result.containsKey('intent')) {
        // Đảm bảo luôn có key slots (Map)
        final slots = result['slots'];
        return {
          'intent': result['intent'] ?? 'unknown',
          'slots': (slots is Map)
              ? Map<String, dynamic>.from(slots)
              : <String, dynamic>{},
          'raw': response,
        };
      }
    } catch (e) {
      // Nếu không parse được, trả về intent mặc định
      return {
        'intent': 'unknown',
        'slots': <String, dynamic>{},
        'raw': response,
      };
    }
    return {
      'intent': 'unknown',
      'slots': <String, dynamic>{},
      'raw': response,
    };
  }

  String _buildPrompt(String text) {
    // Prompt chuẩn cho LLM intent classification - Flashcard focused
    return '''
You are a flashcard learning assistant. Recognize the following voice commands:

**Book Management:**
- listBook: Show list of available books
  Examples: "Show books", "List my books", "What books do I have?"
- selectBook: Open a specific book for learning. Slot: bookName (string)
  Examples: "Open English book", "Study vocabulary book", "Open TOEIC basics"

**Card Navigation (when in flashcard screen):**
- nextCard: Move to next flashcard
  Examples: "Next card", "Next one", "Go to next", "Show next"
- prevCard: Move to previous flashcard
  Examples: "Previous card", "Go back", "Last card", "Back one"

**Card Interaction (when in flashcard screen):**
- flipCard: Flip card to see details/meaning
  Examples: "Flip", "Show meaning", "Flip card", "Turn it over"
- bookmarkWord: Bookmark current word for later review
  Examples: "Bookmark", "Save this word", "Mark this", "Remember this"

**Conversation:**
- startConversation: Start free conversation with AI assistant
  Examples: "Let's chat", "Start conversation", "Talk to me", "I want to talk"

**Important:** Return ONLY the intent name and slots (if any) in JSON format.

Example:
Input: "Next card"
Output: {"intent": "nextCard", "slots": {}}

Input: "Open TOEIC book"
Output: {"intent": "selectBook", "slots": {"bookName": "TOEIC"}}

Input: "Show my books"
Output: {"intent": "listBook", "slots": {}}
''';
  }
}
