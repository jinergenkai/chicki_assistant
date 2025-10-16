/// Represents an intent detected from user speech or simulator
class VoiceIntentPayload {
  /// Intent name (e.g., "selectBook", "nextVocab", "readAloud")
  final String intent;
  
  /// Extracted parameters/slots from the intent
  /// Example: {"bookName": "English Starter", "topicName": "Animals"}
  final Map<String, dynamic> slots;
  
  /// Confidence score (0.0 - 1.0)
  final double confidence;
  
  /// Timestamp when intent was detected
  final DateTime timestamp;

  VoiceIntentPayload({
    required this.intent,
    required this.slots,
    required this.confidence,
    required this.timestamp,
  });

  /// Create from JSON
  factory VoiceIntentPayload.fromJson(Map<String, dynamic> json) {
    return VoiceIntentPayload(
      intent: json['intent'] as String,
      slots: Map<String, dynamic>.from(json['slots'] as Map),
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'slots': slots,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'VoiceIntentPayload(intent: $intent, slots: $slots, confidence: $confidence)';
  }

  /// Create a copy with modified fields
  VoiceIntentPayload copyWith({
    String? intent,
    Map<String, dynamic>? slots,
    double? confidence,
    DateTime? timestamp,
  }) {
    return VoiceIntentPayload(
      intent: intent ?? this.intent,
      slots: slots ?? this.slots,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}