import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import '../models/book.dart';
import '../models/vocabulary.dart';
import '../models/journal_entry.dart';
import '../models/story_chapter.dart';
import 'book_service.dart';
import 'vocabulary.service.dart';
import 'journal_service.dart';
import 'story_service.dart';

/// Service for importing and exporting books with all associated data
/// Supports all 3 book types: FlashBook, Journal, Story
class BookImportExportService {
  final BookService _bookService = Get.find<BookService>();
  final VocabularyService _vocabService = Get.find<VocabularyService>();
  final JournalService _journalService = Get.find<JournalService>();
  final StoryService _storyService = Get.find<StoryService>();

  /// Export a book to JSON with all associated data
  /// Returns JSON string ready to save to file
  Future<String> exportBook(String bookId) async {
    final book = _bookService.getBook(bookId);
    if (book == null) {
      throw Exception('Book not found: $bookId');
    }

    Map<String, dynamic> exportData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'book': book.toJson(),
    };

    // Export data based on book type
    switch (book.type) {
      case BookType.flashBook:
        final vocabs = _vocabService.getByBookIdSorted(bookId);
        exportData['vocabularies'] = vocabs.map((v) => v.toJson()).toList();
        break;

      case BookType.journal:
        final entries = _journalService.getEntriesByBookIdSorted(bookId);
        exportData['journalEntries'] = entries.map((e) => e.toJson()).toList();
        break;

      case BookType.story:
        final chapters = _storyService.getChaptersByBookIdSorted(bookId);
        exportData['storyChapters'] = chapters.map((c) => c.toJson()).toList();
        break;
    }

    return JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Export book to file
  Future<File> exportBookToFile(String bookId, String filePath) async {
    final jsonString = await exportBook(bookId);
    final file = File(filePath);
    await file.writeAsString(jsonString);
    return file;
  }

  /// Import a book from JSON string
  /// Returns the imported book ID
  Future<String> importBook(String jsonString, {bool overwrite = false}) async {
    final data = json.decode(jsonString) as Map<String, dynamic>;

    // Validate format
    if (!data.containsKey('book')) {
      throw Exception('Invalid book export format: missing "book" field');
    }

    final bookData = data['book'] as Map<String, dynamic>;
    final bookType = BookType.values.firstWhere(
      (t) => t.toString() == 'BookType.${bookData['type']}',
      orElse: () => BookType.flashBook,
    );

    // Generate new book ID for import (to avoid conflicts)
    final originalId = bookData['id'] as String;
    final newBookId = 'imported_${DateTime.now().millisecondsSinceEpoch}';

    // Check if book already exists (by title + author)
    final existingBook = _findExistingBook(
      bookData['title'] as String,
      bookData['author'] as String?,
    );

    String finalBookId;
    if (existingBook != null && !overwrite) {
      throw Exception(
        'Book "${bookData['title']}" already exists. Use overwrite=true to replace.',
      );
    } else if (existingBook != null && overwrite) {
      finalBookId = existingBook.id;
      // Delete old data
      await _deleteBookData(existingBook);
    } else {
      finalBookId = newBookId;
    }

    // Create book
    final book = Book.fromJson({
      ...bookData,
      'id': finalBookId,
      'isCustom': true,
      'source': BookSource.imported.toString().split('.').last,
      'originalOwnerId': bookData['ownerId'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _bookService.addCustomBook(book);

    // Import associated data based on book type
    switch (bookType) {
      case BookType.flashBook:
        await _importVocabularies(data, originalId, finalBookId);
        break;

      case BookType.journal:
        await _importJournalEntries(data, originalId, finalBookId);
        break;

      case BookType.story:
        await _importStoryChapters(data, originalId, finalBookId);
        break;
    }

    return finalBookId;
  }

  /// Import book from file
  Future<String> importBookFromFile(String filePath, {bool overwrite = false}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final jsonString = await file.readAsString();
    return await importBook(jsonString, overwrite: overwrite);
  }

  /// Import vocabularies for FlashBook
  Future<void> _importVocabularies(
    Map<String, dynamic> data,
    String originalBookId,
    String newBookId,
  ) async {
    if (!data.containsKey('vocabularies')) return;

    final vocabsData = data['vocabularies'] as List;
    for (final vocabData in vocabsData) {
      final vocab = Vocabulary.fromJson({
        ...vocabData as Map<String, dynamic>,
        'bookId': newBookId,
        'id': null, // Let service generate new ID
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSync': false,
        'isDeleted': false,
      });

      await _vocabService.upsertVocabulary(vocab);
    }
  }

  /// Import journal entries for Journal
  Future<void> _importJournalEntries(
    Map<String, dynamic> data,
    String originalBookId,
    String newBookId,
  ) async {
    if (!data.containsKey('journalEntries')) return;

    final entriesData = data['journalEntries'] as List;
    for (final entryData in entriesData) {
      final entry = JournalEntry.fromJson({
        ...entryData as Map<String, dynamic>,
        'bookId': newBookId,
        'id': null, // Let service generate new ID
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _journalService.createEntry(
        bookId: entry.bookId,
        date: entry.date,
        title: entry.title,
        content: entry.content,
        mood: entry.mood,
        tags: entry.tags,
        attachments: entry.attachments,
      );
    }
  }

  /// Import story chapters for Story
  Future<void> _importStoryChapters(
    Map<String, dynamic> data,
    String originalBookId,
    String newBookId,
  ) async {
    if (!data.containsKey('storyChapters')) return;

    final chaptersData = data['storyChapters'] as List;
    for (final chapterData in chaptersData) {
      final chapter = StoryChapter.fromJson({
        ...chapterData as Map<String, dynamic>,
        'bookId': newBookId,
        'id': null, // Let service generate new ID
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        // Reset reading progress on import
        'isCompleted': false,
        'lastReadPosition': 0,
        'progressPercent': 0.0,
        'lastReadAt': null,
      });

      await _storyService.createChapter(
        bookId: chapter.bookId,
        chapterNumber: chapter.chapterNumber,
        title: chapter.title,
        content: chapter.content,
        summary: chapter.summary,
      );
    }
  }

  /// Find existing book by title and author
  Book? _findExistingBook(String title, String? author) {
    final allBooks = _bookService.loadCustomBooks();
    return allBooks.firstWhereOrNull(
      (book) =>
          book.title.toLowerCase() == title.toLowerCase() &&
          (author == null || book.author?.toLowerCase() == author.toLowerCase()),
    );
  }

  /// Delete all data associated with a book
  Future<void> _deleteBookData(Book book) async {
    switch (book.type) {
      case BookType.flashBook:
        final vocabs = _vocabService.getByBookId(book.id);
        for (final vocab in vocabs) {
          await _vocabService.deleteVocabulary(vocab);
        }
        break;

      case BookType.journal:
        final entries = _journalService.getEntriesByBookId(book.id);
        for (final entry in entries) {
          await _journalService.deleteEntry(entry.id!);
        }
        break;

      case BookType.story:
        final chapters = _storyService.getChaptersByBookId(book.id);
        for (final chapter in chapters) {
          await _storyService.deleteChapter(chapter.id!);
        }
        break;
    }

    await _bookService.deleteBook(book.id);
  }

  /// Validate JSON format before import
  bool validateImportJson(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Check required fields
      if (!data.containsKey('book')) return false;
      if (!data.containsKey('version')) return false;

      final bookData = data['book'] as Map<String, dynamic>;
      if (!bookData.containsKey('id')) return false;
      if (!bookData.containsKey('title')) return false;
      if (!bookData.containsKey('type')) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get import preview info without actually importing
  Map<String, dynamic> getImportPreview(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final bookData = data['book'] as Map<String, dynamic>;

    final bookType = BookType.values.firstWhere(
      (t) => t.toString() == 'BookType.${bookData['type']}',
      orElse: () => BookType.flashBook,
    );

    int itemCount = 0;
    String itemType = '';

    switch (bookType) {
      case BookType.flashBook:
        itemCount = (data['vocabularies'] as List?)?.length ?? 0;
        itemType = 'vocabularies';
        break;
      case BookType.journal:
        itemCount = (data['journalEntries'] as List?)?.length ?? 0;
        itemType = 'journal entries';
        break;
      case BookType.story:
        itemCount = (data['storyChapters'] as List?)?.length ?? 0;
        itemType = 'chapters';
        break;
    }

    return {
      'title': bookData['title'],
      'author': bookData['author'],
      'description': bookData['description'],
      'type': bookType.toString().split('.').last,
      'itemCount': itemCount,
      'itemType': itemType,
      'exportedAt': data['exportedAt'],
      'version': data['version'],
    };
  }
}
