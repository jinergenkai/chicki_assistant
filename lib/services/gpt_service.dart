import 'dart:async';
import '../core/logger.dart';
import '../core/app_config.dart';
import '../core/constants.dart';
import '../models/message.dart';

abstract class GPTService {
  Future<String> generateResponse(String userInput);
  Future<void> initialize();
  Future<void> resetContext();
}

class OpenAIService implements GPTService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  final _config = AppConfig();
  final List<Message> _conversationHistory = [];
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    try {
      // TODO: Initialize OpenAI client with actual API key
      // For now, we'll just simulate initialization
      _isInitialized = true;
      logger.info('GPT service initialized');
    } catch (e) {
      logger.error('Failed to initialize GPT service', e);
      rethrow;
    }
  }

  @override
  Future<String> generateResponse(String userInput) async {
    if (!_isInitialized) {
      throw Exception('GPT Service not initialized');
    }

    try {
      // Add user message to history
      _conversationHistory.add(Message(
        role: 'user',
        content: userInput,
      ));

      logger.info('Generating response for: $userInput');

      // TODO: Implement actual API call to OpenAI
      // For now, return a test response
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      final response = _generateTestResponse(userInput);

      // Add assistant response to history
      _conversationHistory.add(Message(
        role: 'assistant',
        content: response,
      ));

      return response;
    } catch (e) {
      logger.error('Error while generating response', e);
      rethrow;
    }
  }

  String _generateTestResponse(String input) {
    if (input.toLowerCase().contains('hello') || input.toLowerCase().contains('hi')) {
      return 'Hello! How can I help you today?';
    } else if (input.toLowerCase().contains('how are you')) {
      return "I'm functioning well, thank you for asking! How can I assist you?";
    } else if (input.toLowerCase().contains('weather')) {
      return "I'm a test response and can't actually check the weather, but I can tell you it's always sunny in the virtual world!";
    } else if (input.toLowerCase().contains('name')) {
      return "I'm your AI assistant, nice to meet you!";
    } else if (input.toLowerCase().contains('thank')) {
      return "You're welcome! Let me know if you need anything else.";
    } else if (input.isEmpty) {
      return "I didn't catch that. Could you please say it again?";
    } else {
      return "I understood you said: '$input'. This is a test response since we haven't integrated the actual GPT API yet. Once integrated, I'll provide more meaningful responses!";
    }
  }

  @override
  Future<void> resetContext() async {
    try {
      _conversationHistory.clear();
      logger.info('Conversation context reset');
    } catch (e) {
      logger.error('Error while resetting context', e);
      rethrow;
    }
  }

  List<Message> get conversationHistory => List.unmodifiable(_conversationHistory);
}