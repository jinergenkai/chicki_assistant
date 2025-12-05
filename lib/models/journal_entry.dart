import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'journal_entry.g.dart';

/// Journal Entry model for diary/journal book type
/// Each entry represents a dated journal entry with content, mood, and tags
@HiveType(typeId: 203)
@JsonSerializable()
class JournalEntry extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String bookId; // Foreign key to Book

  @HiveField(2)
  DateTime date; // Entry date (user can backdate)

  @HiveField(3)
  String title; // Entry title

  @HiveField(4)
  String content; // Journal text content

  @HiveField(5)
  String? mood; // Optional mood indicator (e.g., 'happy', 'sad', 'excited')

  @HiveField(6)
  List<String>? tags; // Optional tags for categorization

  @HiveField(7)
  List<String>? attachments; // Optional file paths (images, etc.)

  @HiveField(8)
  int? wordCount; // Auto-calculated word count

  @HiveField(9)
  bool isFavorite; // Mark as favorite entry

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  JournalEntry({
    this.id,
    required this.bookId,
    required this.date,
    required this.title,
    required this.content,
    this.mood,
    this.tags,
    this.attachments,
    this.wordCount,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Generate ID if not provided
    id ??= 'journal_${DateTime.now().millisecondsSinceEpoch}';

    // Calculate word count from content
    wordCount ??= _calculateWordCount(content);
  }

  /// Calculate word count from text content
  static int _calculateWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Update word count when content changes
  void updateWordCount() {
    wordCount = _calculateWordCount(content);
    updatedAt = DateTime.now();
  }

  /// JSON serialization
  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);

  Map<String, dynamic> toJson() => _$JournalEntryToJson(this);

  @override
  String toString() {
    return 'JournalEntry(id: $id, bookId: $bookId, date: $date, title: $title, wordCount: $wordCount)';
  }
}
