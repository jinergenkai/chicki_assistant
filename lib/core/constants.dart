import 'dart:ui';

class AppConstants {
  // Base URLs
  // static const String baseUrl = 'http://192.168.0.103:1337/v1';
  // static const String baseUrl = 'http://192.168.95.91:11434/v1';
  static const String baseUrl = 'http://huynhhanh.com:9443/api/v1';
  // static const String baseUrl = 'http://192.168.0.105:9443/api/v1';

  // API Keys
  static const String openAIKey = 'YOUR_OPENAI_KEY';
  static const String janKey = '1';
  
  // App Settings
  static const String appName = 'Voice AI Assistant';
  static const int maxRetries = 3;
  
  // Messages
  static const String listeningMessage = 'Listening...';
  static const String processingMessage = 'Processing...';
  static const String errorMessage = 'Something went wrong';

  static const Color backgroundColor = Color.fromARGB(255, 221, 230, 238); // light grey bg
  // static const Color backgroundColor = Color.fromARGB(255, 214, 222, 230); // light grey bg

}