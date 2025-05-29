class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Configuration properties
  bool isDebugMode = true;
  String apiEndpoint = 'https://api.openai.com/v1';
  
  // Voice settings
  double speechRate = 0.7;
  String defaultLanguage = 'en-US';
  
  // GPT settings
  String gptModel = 'gpt-3.5-turbo';
  int maxTokens = 150;
  double temperature = 0.7;
  
  // Initialize config
  Future<void> init() async {
    // Load any configuration from local storage or environment
    // This will be implemented later as needed
  }
}