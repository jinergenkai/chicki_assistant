import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/controllers/app_config.controller.dart';

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
    String? model,
    List<Map<String, String>>? history,
    String? bearerToken,
  }) async {
    final AppConfigController config = Get.find<AppConfigController>();
    try {
      final data = {
        "model": model ?? config.gptModel.value,
        "messages": [
          {"role": "system", "content": "act like teacher, friend of user, answer short"},
          // if (history != null) ...history,
          {"role": "user", "content": prompt}
        ]
      };
      final options = Options(
        headers: (bearerToken ?? config.apiKey.value).isNotEmpty ? {"Authorization": "Bearer ${bearerToken ?? config.apiKey.value}"} : null,
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

  /// Lấy danh sách model từ local LLM API (ví dụ Ollama, LM Studio)
  Future<List<String>> fetchModels({String? bearerToken}) async {
    try {
      final options = Options(
        headers: (bearerToken ?? '').isNotEmpty ? {"Authorization": "Bearer $bearerToken"} : null,
        sendTimeout: const Duration(milliseconds: 120000),
        receiveTimeout: const Duration(milliseconds: 120000),
      );
      final response = await dio.get(
        '/models',
        options: options,
      );
      // Tùy vào API trả về, có thể cần parse lại cho phù hợp
      if (response.data is List) {
        return (response.data as List).map((e) => e.toString()).toList();
      }
      if (response.data is Map) {
        if (response.data['models'] is List) {
          return (response.data['models'] as List).map((e) => e.toString()).toList();
        }
        if (response.data['data'] is List) {
          return (response.data['data'] as List).map((e) => e['name']?.toString() ?? e.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
