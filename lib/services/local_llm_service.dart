import 'dart:async';
import 'package:chicki_buddy/core/constants.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:chicki_buddy/network/llm.api.dart';
import 'package:logger/logger.dart';
import '../models/message.dart';
import 'llm_service.dart';
/// Local LLM Service sử dụng API tương thích OpenAI (ví dụ: Ollama, LM Studio, v.v.)
class LocalLLMService implements LLMService {
  static final LocalLLMService _instance = LocalLLMService._internal();
  factory LocalLLMService() => _instance;
  LocalLLMService._internal();

  final List<Message> _conversationHistory = [];
  bool _isInitialized = false;
  final Logger _logger = Logger();

  @override
  Future<void> initialize() async {
    try {
      // Khởi tạo OpenAI client với endpoint local
      OpenAI.apiKey = "1"; // Local server thường không cần key
      OpenAI.baseUrl = "http://192.168.0.106:1337/v1";
      _isInitialized = true;
      _logger.i('Local LLM service initialized (dart_openai)');
    } catch (e) {
      _logger.e('Failed to initialize Local LLM service', error: e);
      rethrow;
    }
  }

  @override
  Future<String> generateResponse(String userInput) async {
    if (!_isInitialized) {
      throw Exception('Local LLM Service not initialized');
    }

    try {
      _conversationHistory.add(Message(
        role: 'user',
        content: userInput,
      ));

      _logger.i('Generating response (local LLM) for: $userInput');

      // Gọi API local LLM qua LlmApi (Dio)
      final history = _conversationHistory
          .map((msg) => {
                "role": msg.role,
                "content": msg.content,
              })
          .toList();

      final responseStr = await LlmApi().chat(
        prompt: userInput,
        model: "gpt-oss:20b",
        history: history,
        bearerToken: AppConstants.janKey,
      );

      _conversationHistory.add(Message(
        role: 'assistant',
        content: responseStr,
      ));

      return responseStr;
    } catch (e) {
      _logger.e('Error while generating response (local LLM)', error: e);
      rethrow;
    }
  }

  @override
  Future<void> resetContext() async {
    try {
      _conversationHistory.clear();
      _logger.i('Local LLM context reset');
    } catch (e) {
      _logger.e('Error while resetting local LLM context', error: e);
      rethrow;
    }
  }

  List<Message> get conversationHistory => List.unmodifiable(_conversationHistory);
}