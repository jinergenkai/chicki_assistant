import 'package:chicki_buddy/voice/dispatcher/intent_classifier_service.dart';

import 'package:chicki_buddy/network/llm.api.dart';
import 'dart:convert';

class LLMIntentClassifierService extends IntentClassifierService {
  final LlmApi _llmApi = LlmApi();

  // Các intent và slot mẫu
  static const _intentList = [
    'listBook',
    'selectBook',
    'listTopic',
    'selectTopic',
    'startConversation',
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
          'slots': (slots is Map) ? Map<String, dynamic>.from(slots) : <String, dynamic>{},
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
    // Prompt chuẩn cho LLM intent classification
    return '''
You are an intent analysis system. The following are the valid intents:
- listBook: list available books
- selectBook: select a specific book, slot: bookName
- listTopic: list available topics
- selectTopic: select a specific topic, slot: topicName
- startConversation: start a conversation
- stopConversation: stop a conversation

Task: Analyze the following sentence and return the result in JSON format, including the intent and any relevant slots (if applicable).

Example:
Input: "I want to read Harry Potter"
Output: {"intent": "selectBook", "slots": {"bookName": "Harry Potter"}}
''';
  }
}
