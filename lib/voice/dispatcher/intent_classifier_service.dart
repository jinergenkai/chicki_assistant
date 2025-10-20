// Base class for intent classification

abstract class IntentClassifierService {
  Future<Map<String, dynamic>> classify(String text);
}