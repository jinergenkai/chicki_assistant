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
    final response = await _llmApi.chat(prompt: prompt);

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
Bạn là hệ thống phân tích ý định người dùng. Dưới đây là các intent hợp lệ:
- listBook: liệt kê danh sách sách
- selectBook: chọn sách, slot: bookName
- listTopic: liệt kê chủ đề
- selectTopic: chọn chủ đề, slot: topicName
- startConversation: bắt đầu hội thoại

Yêu cầu: Phân tích câu sau và trả về kết quả dạng JSON với intent và slots (nếu có).
Ví dụ:
Input: "Tôi muốn đọc sách Harry Potter"
Output: {"intent": "selectBook", "slots": {"bookName": "Harry Potter"}}

Input: "$text"
Output:
''';
  }
}