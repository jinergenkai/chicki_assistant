import 'package:hive/hive.dart';
import '../models/story_chapter.dart';

/// Service for managing story chapters
/// Handles CRUD operations for reading/story book type
class StoryService {
  static const String boxName = "storyChapterBox";
  late Box<StoryChapter> _chapterBox;

  Future<void> init() async {
    _chapterBox = await Hive.openBox<StoryChapter>(boxName);
  }

  /// Create a new chapter
  Future<StoryChapter> createChapter({
    required String bookId,
    required int chapterNumber,
    required String title,
    required String content,
    String? summary,
  }) async {
    // Check for duplicate chapter number
    final existingChapter = getChapterByNumber(bookId, chapterNumber);
    if (existingChapter != null) {
      throw Exception('Chapter $chapterNumber already exists in this book');
    }

    final chapter = StoryChapter(
      bookId: bookId,
      chapterNumber: chapterNumber,
      title: title.trim(),
      content: content.trim(),
      summary: summary?.trim(),
    );

    await _chapterBox.put(chapter.id, chapter);
    return chapter;
  }

  /// Update an existing chapter
  Future<void> updateChapter(StoryChapter chapter) async {
    chapter.updatedAt = DateTime.now();
    await _chapterBox.put(chapter.id, chapter);
  }

  /// Delete a chapter
  Future<void> deleteChapter(String chapterId) async {
    await _chapterBox.delete(chapterId);
  }

  /// Get a single chapter by ID
  StoryChapter? getChapter(String chapterId) {
    return _chapterBox.get(chapterId);
  }

  /// Get a chapter by book and chapter number
  StoryChapter? getChapterByNumber(String bookId, int chapterNumber) {
    return _chapterBox.values.firstWhere(
      (chapter) => chapter.bookId == bookId && chapter.chapterNumber == chapterNumber,
      orElse: () => null as StoryChapter,
    );
  }

  /// Get all chapters for a specific book
  List<StoryChapter> getChaptersByBookId(String bookId) {
    return _chapterBox.values
        .where((chapter) => chapter.bookId == bookId)
        .toList();
  }

  /// Get chapters sorted by chapter number
  List<StoryChapter> getChaptersByBookIdSorted(String bookId) {
    final chapters = getChaptersByBookId(bookId);
    chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return chapters;
  }

  /// Get completed chapters
  List<StoryChapter> getCompletedChapters(String bookId) {
    return _chapterBox.values
        .where((chapter) => chapter.bookId == bookId && chapter.isCompleted)
        .toList();
  }

  /// Get in-progress chapters (started but not completed)
  List<StoryChapter> getInProgressChapters(String bookId) {
    return _chapterBox.values
        .where((chapter) =>
            chapter.bookId == bookId &&
            !chapter.isCompleted &&
            (chapter.progressPercent ?? 0) > 0)
        .toList();
  }

  /// Get unread chapters
  List<StoryChapter> getUnreadChapters(String bookId) {
    return _chapterBox.values
        .where((chapter) =>
            chapter.bookId == bookId &&
            (chapter.progressPercent ?? 0) == 0)
        .toList();
  }

  /// Get the next unread chapter
  StoryChapter? getNextUnreadChapter(String bookId) {
    final unreadChapters = getUnreadChapters(bookId);
    if (unreadChapters.isEmpty) return null;

    unreadChapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return unreadChapters.first;
  }

  /// Get the current reading chapter (last chapter with progress)
  StoryChapter? getCurrentReadingChapter(String bookId) {
    final chapters = getChaptersByBookId(bookId);
    if (chapters.isEmpty) return null;

    // Find the last chapter that was read (has lastReadAt)
    final chaptersWithProgress = chapters
        .where((c) => c.lastReadAt != null)
        .toList();

    if (chaptersWithProgress.isEmpty) {
      // No progress yet, return first chapter
      final sorted = chapters..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
      return sorted.first;
    }

    // Return the most recently read chapter
    chaptersWithProgress.sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
    return chaptersWithProgress.first;
  }

  /// Update reading progress
  Future<void> updateProgress(StoryChapter chapter, int currentPosition) async {
    chapter.updateProgress(currentPosition);
    await _chapterBox.put(chapter.id, chapter);
  }

  /// Mark chapter as completed
  Future<void> markCompleted(StoryChapter chapter) async {
    chapter.markCompleted();
    await _chapterBox.put(chapter.id, chapter);
  }

  /// Reset chapter progress
  Future<void> resetProgress(StoryChapter chapter) async {
    chapter.resetProgress();
    await _chapterBox.put(chapter.id, chapter);
  }

  /// Reset all progress for a book
  Future<void> resetBookProgress(String bookId) async {
    final chapters = getChaptersByBookId(bookId);
    for (final chapter in chapters) {
      chapter.resetProgress();
      await _chapterBox.put(chapter.id, chapter);
    }
  }

  /// Get book reading statistics
  Map<String, dynamic> getBookStatistics(String bookId) {
    final chapters = getChaptersByBookId(bookId);

    if (chapters.isEmpty) {
      return {
        'totalChapters': 0,
        'completedChapters': 0,
        'progressPercent': 0.0,
        'totalWords': 0,
        'totalReadingTime': 0,
        'lastReadAt': null,
      };
    }

    final completedCount = chapters.where((c) => c.isCompleted).length;
    final totalWords = chapters.fold<int>(0, (sum, c) => sum + (c.wordCount ?? 0));
    final totalReadingTime = chapters.fold<int>(0, (sum, c) => sum + (c.readingTime ?? 0));

    // Find the most recent reading activity
    DateTime? lastRead;
    for (final chapter in chapters) {
      if (chapter.lastReadAt != null) {
        if (lastRead == null || chapter.lastReadAt!.isAfter(lastRead)) {
          lastRead = chapter.lastReadAt;
        }
      }
    }

    // Calculate overall progress
    final overallProgress = (completedCount / chapters.length * 100);

    return {
      'totalChapters': chapters.length,
      'completedChapters': completedCount,
      'inProgressChapters': getInProgressChapters(bookId).length,
      'unreadChapters': getUnreadChapters(bookId).length,
      'progressPercent': overallProgress,
      'totalWords': totalWords,
      'totalReadingTime': totalReadingTime,
      'estimatedTimeRemaining': _calculateTimeRemaining(chapters),
      'lastReadAt': lastRead,
    };
  }

  /// Calculate estimated time remaining for unread chapters
  int _calculateTimeRemaining(List<StoryChapter> chapters) {
    int remainingTime = 0;
    for (final chapter in chapters) {
      if (!chapter.isCompleted) {
        final chapterReadingTime = chapter.readingTime ?? 0;
        final progress = chapter.progressPercent ?? 0;
        final remainingPercent = (100 - progress) / 100;
        remainingTime += (chapterReadingTime * remainingPercent).ceil();
      }
    }
    return remainingTime;
  }

  /// Bulk import chapters (useful for importing stories)
  Future<List<StoryChapter>> importChapters(List<StoryChapter> chapters) async {
    for (final chapter in chapters) {
      await _chapterBox.put(chapter.id, chapter);
    }
    return chapters;
  }

  /// Close the box
  Future<void> close() async {
    await _chapterBox.close();
  }
}
