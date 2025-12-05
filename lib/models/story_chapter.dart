import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'story_chapter.g.dart';

/// Story Chapter model for reading/story book type
/// Each chapter represents a section of a story with reading progress tracking
@HiveType(typeId: 204)
@JsonSerializable()
class StoryChapter extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String bookId; // Foreign key to Book

  @HiveField(2)
  int chapterNumber; // Chapter sequence (1, 2, 3, ...)

  @HiveField(3)
  String title; // Chapter title

  @HiveField(4)
  String content; // Chapter text content

  @HiveField(5)
  String? summary; // Optional chapter summary

  @HiveField(6)
  int? readingTime; // Estimated reading time in minutes

  @HiveField(7)
  int? wordCount; // Auto-calculated word count

  @HiveField(8)
  bool isCompleted; // Reading completion status

  @HiveField(9)
  int? lastReadPosition; // Last character position read (for resume reading)

  @HiveField(10)
  double? progressPercent; // Reading progress percentage (0-100)

  @HiveField(11)
  DateTime? lastReadAt; // Last time this chapter was read

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  StoryChapter({
    this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.summary,
    this.readingTime,
    this.wordCount,
    this.isCompleted = false,
    this.lastReadPosition,
    this.progressPercent,
    this.lastReadAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Generate ID if not provided
    id ??= 'chapter_${bookId}_$chapterNumber';

    // Calculate word count and reading time if not provided
    wordCount ??= _calculateWordCount(content);
    readingTime ??= _calculateReadingTime(wordCount!);

    // Initialize progress if not set
    progressPercent ??= isCompleted ? 100.0 : 0.0;
  }

  /// Calculate word count from text content
  static int _calculateWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Calculate estimated reading time (assuming 200 words per minute)
  static int _calculateReadingTime(int wordCount) {
    if (wordCount == 0) return 0;
    return (wordCount / 200).ceil(); // Round up to nearest minute
  }

  /// Update reading progress
  void updateProgress(int currentPosition) {
    lastReadPosition = currentPosition;
    progressPercent = (currentPosition / content.length * 100).clamp(0.0, 100.0);

    if (progressPercent! >= 95.0) {
      isCompleted = true;
    }

    lastReadAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Mark chapter as completed
  void markCompleted() {
    isCompleted = true;
    progressPercent = 100.0;
    lastReadPosition = content.length;
    lastReadAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Reset reading progress
  void resetProgress() {
    isCompleted = false;
    progressPercent = 0.0;
    lastReadPosition = 0;
    updatedAt = DateTime.now();
  }

  /// JSON serialization
  factory StoryChapter.fromJson(Map<String, dynamic> json) =>
      _$StoryChapterFromJson(json);

  Map<String, dynamic> toJson() => _$StoryChapterToJson(this);

  @override
  String toString() {
    return 'StoryChapter(id: $id, bookId: $bookId, chapter: $chapterNumber, title: $title, progress: ${progressPercent?.toStringAsFixed(1)}%)';
  }
}
