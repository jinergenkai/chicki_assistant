/// Unified message format for communication between main and foreground isolates
/// This provides a consistent structure for all messages

enum MessageType {
  // System messages
  status,           // System status updates
  config,           // Configuration updates
  
  // Voice state messages
  voiceState,       // Voice state changes (idle, listening, processing, etc.)
  micLifecycle,     // Microphone lifecycle (started, stopped)
  
  // Voice data messages
  recognizedText,   // STT recognized text
  rmsLevel,         // Audio RMS level
  
  // Intent messages
  intent,           // Intent request (from UI or speech)
  intentResult,     // Intent execution result
  
  // Command messages
  command,          // Control commands (startListening, stopListening, etc.)
  
  // Wakeword messages
  wakeword,         // Wakeword detection
  
  // Error messages
  error,            // Error information
}

enum MessageSource {
  ui,               // From UI interaction
  speech,           // From speech recognition
  system,           // From system/internal
}

class IsolateMessage {
  final MessageType type;
  final Map<String, dynamic> data;
  final MessageSource? source;
  final DateTime timestamp;

  IsolateMessage({
    required this.type,
    required this.data,
    this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from raw map (for backward compatibility)
  factory IsolateMessage.fromMap(Map<String, dynamic> map) {
    // Try to detect message type from map keys
    MessageType type;
    Map<String, dynamic> data = {};
    MessageSource? source;

    if (map.containsKey('type')) {
      // New format
      type = MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.status,
      );
      data = Map<String, dynamic>.from(map['data'] ?? {});
      if (map['source'] != null) {
        source = MessageSource.values.firstWhere(
          (e) => e.name == map['source'],
          orElse: () => MessageSource.system,
        );
      }
    } else {
      // Legacy format - detect type from keys
      if (map.containsKey('command')) {
        type = MessageType.command;
        data = map;
      } else if (map.containsKey('intent')) {
        type = MessageType.intent;
        data = map;
        source = map['source'] == 'speech' ? MessageSource.speech : MessageSource.ui;
      } else if (map.containsKey('state')) {
        type = MessageType.voiceState;
        data = map;
      } else if (map.containsKey('micLifecycle')) {
        type = MessageType.micLifecycle;
        data = map;
      } else if (map.containsKey('recognizedText')) {
        type = MessageType.recognizedText;
        data = map;
      } else if (map.containsKey('rmsDB')) {
        type = MessageType.rmsLevel;
        data = map;
      } else if (map.containsKey('voiceAction')) {
        type = MessageType.intentResult;
        data = map;
      } else if (map.containsKey('wakewordDetected')) {
        type = MessageType.wakeword;
        data = map;
      } else if (map.containsKey('config')) {
        type = MessageType.config;
        data = map;
      } else if (map.containsKey('error')) {
        type = MessageType.error;
        data = map;
      } else {
        type = MessageType.status;
        data = map;
      }
    }

    return IsolateMessage(
      type: type,
      data: data,
      source: source,
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }

  /// Convert to map for sending
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'data': data,
      if (source != null) 'source': source!.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Helper constructors for common message types
  
  static IsolateMessage status(String status, {Map<String, dynamic>? extra}) {
    return IsolateMessage(
      type: MessageType.status,
      data: {'status': status, ...?extra},
      source: MessageSource.system,
    );
  }

  static IsolateMessage voiceState(String state, {String? error}) {
    return IsolateMessage(
      type: MessageType.voiceState,
      data: {'state': state, if (error != null) 'error': error},
      source: MessageSource.system,
    );
  }

  static IsolateMessage micLifecycle(String lifecycle) {
    return IsolateMessage(
      type: MessageType.micLifecycle,
      data: {'lifecycle': lifecycle},
      source: MessageSource.system,
    );
  }

  static IsolateMessage recognizedText(String text) {
    return IsolateMessage(
      type: MessageType.recognizedText,
      data: {'text': text},
      source: MessageSource.speech,
    );
  }

  static IsolateMessage rmsLevel(double level) {
    return IsolateMessage(
      type: MessageType.rmsLevel,
      data: {'level': level},
      source: MessageSource.system,
    );
  }

  static IsolateMessage intent({
    required String intent,
    Map<String, dynamic>? slots,
    required MessageSource source,
  }) {
    return IsolateMessage(
      type: MessageType.intent,
      data: {
        'intent': intent,
        'slots': slots ?? {},
      },
      source: source,
    );
  }

  static IsolateMessage intentResult(Map<String, dynamic> result) {
    return IsolateMessage(
      type: MessageType.intentResult,
      data: result,
      source: MessageSource.system,
    );
  }

  static IsolateMessage command(String command, {Map<String, dynamic>? params}) {
    return IsolateMessage(
      type: MessageType.command,
      data: {'command': command, ...?params},
      source: MessageSource.ui,
    );
  }

  static IsolateMessage wakeword() {
    return IsolateMessage(
      type: MessageType.wakeword,
      data: {'detected': true},
      source: MessageSource.system,
    );
  }

  static IsolateMessage config(Map<String, dynamic> config) {
    return IsolateMessage(
      type: MessageType.config,
      data: {'config': config},
      source: MessageSource.system,
    );
  }

  static IsolateMessage error(String error, {String? details}) {
    return IsolateMessage(
      type: MessageType.error,
      data: {
        'error': error,
        if (details != null) 'details': details,
      },
      source: MessageSource.system,
    );
  }

  @override
  String toString() {
    return 'IsolateMessage(type: ${type.name}, source: ${source?.name}, data: $data)';
  }
}