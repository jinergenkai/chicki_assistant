/// Maintains the current context of the voice session
/// This represents what the user is currently viewing/interacting with
class VoiceStateContext {
  /// Currently selected book ID
  String? currentBookId;
  
  /// Currently selected topic ID
  String? currentTopicId;
  
  /// Current vocabulary card index (0-based)
  int? currentCardIndex;
  
  /// Current screen/node in the intent graph
  /// Examples: "idle", "bookSelected", "topicSelected", "vocabCard"
  String? currentScreen;
  
  /// Current mode of interaction
  /// Examples: "learning", "review", "quiz", "idle"
  String? mode;
  
  /// Additional metadata
  Map<String, dynamic>? metadata;

  VoiceStateContext({
    this.currentBookId,
    this.currentTopicId,
    this.currentCardIndex,
    this.currentScreen,
    this.mode,
    this.metadata,
  });

  /// Create from JSON (for persistence)
  factory VoiceStateContext.fromJson(Map<String, dynamic> json) {
    return VoiceStateContext(
      currentBookId: json['currentBookId'] as String?,
      currentTopicId: json['currentTopicId'] as String?,
      currentCardIndex: json['currentCardIndex'] as int?,
      currentScreen: json['currentScreen'] as String?,
      mode: json['mode'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'currentBookId': currentBookId,
      'currentTopicId': currentTopicId,
      'currentCardIndex': currentCardIndex,
      'currentScreen': currentScreen,
      'mode': mode,
      'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  VoiceStateContext copyWith({
    String? currentBookId,
    String? currentTopicId,
    int? currentCardIndex,
    String? currentScreen,
    String? mode,
    Map<String, dynamic>? metadata,
  }) {
    return VoiceStateContext(
      currentBookId: currentBookId ?? this.currentBookId,
      currentTopicId: currentTopicId ?? this.currentTopicId,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      currentScreen: currentScreen ?? this.currentScreen,
      mode: mode ?? this.mode,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Reset to initial state
  void reset() {
    currentBookId = null;
    currentTopicId = null;
    currentCardIndex = null;
    currentScreen = 'idle';
    mode = 'idle';
    metadata = null;
  }

  @override
  String toString() {
    return 'VoiceStateContext(screen: $currentScreen, book: $currentBookId, topic: $currentTopicId, card: $currentCardIndex, mode: $mode)';
  }

  /// Check if we're in a specific screen
  bool isInScreen(String screen) => currentScreen == screen;
  
  /// Check if a book is selected
  bool get hasBook => currentBookId != null;
  
  /// Check if a topic is selected
  bool get hasTopic => currentTopicId != null;
  
  /// Check if we're viewing a card
  bool get hasCard => currentCardIndex != null;
}