/// Represents an action to be performed by the UI in response to an intent
class VoiceActionEvent {
  /// Action type (e.g., "navigateToBook", "showCard", "highlightTopic")
  final String action;
  
  /// Action parameters/data
  /// Example: {"bookId": "book_001", "topicId": "topic_005"}
  final Map<String, dynamic> data;
  
  /// Whether this action requires the UI to be visible
  /// If true and UI is not visible, may prompt user to open app
  final bool requiresUI;

  VoiceActionEvent({
    required this.action,
    required this.data,
    this.requiresUI = true,
  });

  /// Create from JSON
  factory VoiceActionEvent.fromJson(Map<String, dynamic> json) {
    return VoiceActionEvent(
      action: json['action'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      requiresUI: json['requiresUI'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'data': data,
      'requiresUI': requiresUI,
    };
  }

  @override
  String toString() {
    return 'VoiceActionEvent(action: $action, data: $data, requiresUI: $requiresUI)';
  }

  /// Create a copy with modified fields
  VoiceActionEvent copyWith({
    String? action,
    Map<String, dynamic>? data,
    bool? requiresUI,
  }) {
    return VoiceActionEvent(
      action: action ?? this.action,
      data: data ?? this.data,
      requiresUI: requiresUI ?? this.requiresUI,
    );
  }
}