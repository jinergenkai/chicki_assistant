import 'dart:async';

abstract class LLMService {
  Future<String> generateResponse(String userInput);
  Future<void> initialize();
  Future<void> resetContext();
}