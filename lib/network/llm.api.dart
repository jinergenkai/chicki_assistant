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
          if (history != null) ...history,
          {"role": "user", "content": prompt}
        ]
      };
      final options = bearerToken != null ? Options(headers: {"Authorization": "Bearer $bearerToken"}) : null;
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
