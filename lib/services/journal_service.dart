import 'package:hive/hive.dart';
import '../models/journal_entry.dart';

/// Service for managing journal entries
/// Handles CRUD operations for diary/journal book type
class JournalService {
  static const String boxName = "journalEntryBox";
  late Box<JournalEntry> _entryBox;

  Future<void> init() async {
    _entryBox = await Hive.openBox<JournalEntry>(boxName);
  }

  /// Create a new journal entry
  Future<JournalEntry> createEntry({
    required String bookId,
    required DateTime date,
    required String title,
    required String content,
    String? mood,
    List<String>? tags,
    List<String>? attachments,
  }) async {
    final entry = JournalEntry(
      bookId: bookId,
      date: date,
      title: title.trim(),
      content: content.trim(),
      mood: mood,
      tags: tags,
      attachments: attachments,
    );

    await _entryBox.put(entry.id, entry);
    return entry;
  }

  /// Update an existing journal entry
  Future<void> updateEntry(JournalEntry entry) async {
    entry.updatedAt = DateTime.now();
    entry.updateWordCount();
    await _entryBox.put(entry.id, entry);
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    await _entryBox.delete(entryId);
  }

  /// Get a single entry by ID
  JournalEntry? getEntry(String entryId) {
    return _entryBox.get(entryId);
  }

  /// Get all entries for a specific book
  List<JournalEntry> getEntriesByBookId(String bookId) {
    return _entryBox.values
        .where((entry) => entry.bookId == bookId)
        .toList();
  }

  /// Get entries sorted by date (newest first)
  List<JournalEntry> getEntriesByBookIdSorted(String bookId, {bool ascending = false}) {
    final entries = getEntriesByBookId(bookId);
    entries.sort((a, b) => ascending
        ? a.date.compareTo(b.date)
        : b.date.compareTo(a.date));
    return entries;
  }

  /// Get entries by date range
  List<JournalEntry> getEntriesByDateRange(
    String bookId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _entryBox.values
        .where((entry) =>
            entry.bookId == bookId &&
            entry.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Get entries by mood
  List<JournalEntry> getEntriesByMood(String bookId, String mood) {
    return _entryBox.values
        .where((entry) =>
            entry.bookId == bookId &&
            entry.mood?.toLowerCase() == mood.toLowerCase())
        .toList();
  }

  /// Get entries by tag
  List<JournalEntry> getEntriesByTag(String bookId, String tag) {
    return _entryBox.values
        .where((entry) =>
            entry.bookId == bookId &&
            entry.tags != null &&
            entry.tags!.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .toList();
  }

  /// Get favorite entries
  List<JournalEntry> getFavoriteEntries(String bookId) {
    return _entryBox.values
        .where((entry) => entry.bookId == bookId && entry.isFavorite)
        .toList();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(JournalEntry entry) async {
    entry.isFavorite = !entry.isFavorite;
    entry.updatedAt = DateTime.now();
    await _entryBox.put(entry.id, entry);
  }

  /// Search entries by keyword in title or content
  List<JournalEntry> searchEntries(String bookId, String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _entryBox.values
        .where((entry) =>
            entry.bookId == bookId &&
            (entry.title.toLowerCase().contains(lowerKeyword) ||
                entry.content.toLowerCase().contains(lowerKeyword)))
        .toList();
  }

  /// Get all unique tags for a book
  List<String> getAllTags(String bookId) {
    final allTags = <String>{};
    for (final entry in _entryBox.values) {
      if (entry.bookId == bookId && entry.tags != null) {
        allTags.addAll(entry.tags!);
      }
    }
    return allTags.toList()..sort();
  }

  /// Get all unique moods for a book
  List<String> getAllMoods(String bookId) {
    final allMoods = <String>{};
    for (final entry in _entryBox.values) {
      if (entry.bookId == bookId && entry.mood != null) {
        allMoods.add(entry.mood!);
      }
    }
    return allMoods.toList()..sort();
  }

  /// Get statistics for a book
  Map<String, dynamic> getBookStatistics(String bookId) {
    final entries = getEntriesByBookId(bookId);

    int totalWords = 0;
    final moodCounts = <String, int>{};

    for (final entry in entries) {
      totalWords += entry.wordCount ?? 0;
      if (entry.mood != null) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }
    }

    return {
      'totalEntries': entries.length,
      'totalWords': totalWords,
      'averageWordsPerEntry': entries.isEmpty ? 0 : (totalWords / entries.length).round(),
      'favoriteCount': entries.where((e) => e.isFavorite).length,
      'moodDistribution': moodCounts,
    };
  }

  /// Close the box
  Future<void> close() async {
    await _entryBox.close();
  }
}
