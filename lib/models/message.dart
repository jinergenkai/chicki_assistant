import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  final String role;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final DateTime timestamp;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
  }) {
    return Message(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  factory Message.user(String content) {
    return Message(role: 'user', content: content);
  }

  factory Message.assistant(String content) {
    return Message(role: 'assistant', content: content); 
  }

  @override
  String toString() {
    return 'Message{role: $role, content: $content, timestamp: $timestamp}';
  }
}