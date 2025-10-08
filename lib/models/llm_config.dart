class LlmConfig {
  String apiKey;
  String model;
  String systemContext;
  int maxTokens;
  double temperature;
  String apiEndpoint;

  LlmConfig({
    this.apiKey = '',
    this.model = 'gpt-3.5-turbo',
    this.systemContext = '',
    this.maxTokens = 150,
    this.temperature = 0.7,
    this.apiEndpoint = 'https://api.openai.com/v1',
  });

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'model': model,
      'systemContext': systemContext,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'apiEndpoint': apiEndpoint,
    };
  }

  // Create from Map (from Hive storage)
  factory LlmConfig.fromMap(Map<String, dynamic> map) {
    return LlmConfig(
      apiKey: map['apiKey'] ?? '',
      model: map['model'] ?? 'gpt-3.5-turbo',
      systemContext: map['systemContext'] ?? '',
      maxTokens: map['maxTokens'] ?? 150,
      temperature: (map['temperature'] ?? 0.7).toDouble(),
      apiEndpoint: map['apiEndpoint'] ?? 'https://api.openai.com/v1',
    );
  }

  // Create a copy with updated fields
  LlmConfig copyWith({
    String? apiKey,
    String? model,
    String? systemContext,
    int? maxTokens,
    double? temperature,
    String? apiEndpoint,
  }) {
    return LlmConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemContext: systemContext ?? this.systemContext,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
    );
  }
}