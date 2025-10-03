import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/network/dio_client.dart';
import 'package:dio/dio.dart';

class LlmApi {
  static final LlmApi _instance = LlmApi._internal();
  final Dio dio = DioClient().dio;

  factory LlmApi() {
    return _instance;
  }

  LlmApi._internal();

  /// Gọi API chat completions tới OpenAI local
  Future<String> chat({
    required String prompt,
    String model = "gpt-oss:20b",
    List<Map<String, String>>? history,
    String? bearerToken,
  }) async {
    try {
      final data = {
        "model": model,
        "messages": [
          {"role": "system", "content": "act like teacher, friend of user, answer short"},
          // if (history != null) ...history,
          {"role": "user", "content": prompt}
        ]
      };
      final options = Options(
        headers: bearerToken != null ? {"Authorization": "Bearer $bearerToken"} : null,
        sendTimeout: const Duration(milliseconds: 120000),
        receiveTimeout: const Duration(milliseconds: 120000),
      );
      logger.info('Sending request: $data to local LLM API');
      final response = await dio.post(
        '/chat/completions',
        data: data,
        options: options,
      );
      final choices = response.data['choices'];
      if (choices != null && choices is List && choices.isNotEmpty) {
        return choices.first['message']['content'] ?? '';
      }
      return '';
    } catch (e) {
      rethrow;
    }
  }
}
