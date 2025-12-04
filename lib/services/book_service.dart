import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import 'vocabulary.service.dart';

class BookService {
  static const String boxName = "bookBox2";
  late Box<Book> _bookBox;

  // BookService(this._bookBox);

  Future<void> init() async {
    _bookBox = await Hive.openBox<Book>(boxName);
  }

  /// Load static books from assets (JSON)
  Future<List<Book>> loadStaticBooks() async {
    final data = await rootBundle.loadString('assets/vocab/books.json');
    final List<dynamic> jsonList = json.decode(data);
    final vocabService = VocabularyService();
    await vocabService.init();
    
    for (final e in jsonList) {
      final bookId = e['id'];
      
      // ✅ Only load vocabs if book doesn't exist in DB yet
      // This prevents overwriting user-added vocabs on reload
      final existingBook = _bookBox.get(bookId);
      
      if (existingBook == null && e['data'] != null && e['data']['vocabList'] is List) {
        // First time loading this static book - load vocabs from JSON
        for (final v in e['data']['vocabList']) {
          final vocab = Vocabulary(
            word: v['word'],
            originLanguage: v['originLanguage'],
            targetLanguage: v['targetLanguage'],
            meaning: v['meaning'],
            exampleSentence: v['example'],
            ttsAudioPath: v['audioUrl'],
            createdAt: DateTime.parse(v['createdAt'] ?? DateTime.now().toIso8601String()),
            updatedAt: DateTime.parse(v['updatedAt'] ?? DateTime.now().toIso8601String()),
            bookId: bookId,
            topic: v['topic'],
          );
          await vocabService.upsertVocabulary(vocab);
        }
        
        // Save static book to DB to mark it as loaded
        final staticBook = Book(
          id: e['id'],
          title: e['title'],
          description: e['description'],
          price: (e['price'] is int) ? (e['price'] as int).toDouble() : e['price'],
          isCustom: false,
          ownerId: e['ownerId'],
          source: BookSource.statics, // Mark as static book
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _bookBox.put(bookId, staticBook);
      }
    }
    
    // Return all books from DB (includes static books with any user modifications)
    return _bookBox.values.where((b) => b.source == BookSource.statics).toList();
  }

  /// Load custom books from Hive
  List<Book> loadCustomBooks() {
    return _bookBox.values.where((b) => b.isCustom).toList();
  }

  /// Merge static and custom books
  Future<List<Book>> loadAllBooks() async {
    final staticBooks = await loadStaticBooks();
    final customBooks = loadCustomBooks();
    return [...staticBooks, ...customBooks];
  }

  /// Add a custom book
  Future<void> addCustomBook(Book book) async {
    await _bookBox.put(book.id, book);
  }

  /// Update a book
  Future<void> updateBook(Book book) async {
    await _bookBox.put(book.id, book);
  }

  /// Delete a book
  Future<void> deleteBook(String bookId) async {
    await _bookBox.delete(bookId);
  }

  /// Get book by ID
  Book? getBook(String bookId) {
    return _bookBox.get(bookId);
  }

  /// Create a new custom book with validation
  Future<Book> createNewBook({
    required String title,
    required String description,
    String? ownerId,
    String? coverImagePath,
    String? author,
    String? category,
  }) async {
    // Validate: Check for duplicate title
    final existingBooks = loadCustomBooks();
    if (existingBooks.any((b) => b.title.toLowerCase() == title.toLowerCase())) {
      throw Exception('Book with title "$title" already exists');
    }

    final now = DateTime.now();
    final book = Book(
      id: 'custom_${now.millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      price: 0,
      isCustom: true,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
      version: '1.0',
      isPublic: false,
      coverImagePath: coverImagePath,
      author: author,
      category: category,
      source: BookSource.userCreated, // Mark as user created
    );

    await _bookBox.put(book.id, book);
    return book;
  }

  /// Mark a book as opened (update lastOpenedAt for recent books tracking)
  Future<void> markBookOpened(String bookId) async {
    final book = _bookBox.get(bookId);
    if (book != null) {
      book.lastOpenedAt = DateTime.now();
      await _bookBox.put(bookId, book);
    }
  }

  /// Get recently opened books (sorted by lastOpenedAt)
  List<Book> getRecentBooks({int limit = 5}) {
    final books = _bookBox.values.toList();

    // Filter books that have been opened
    final openedBooks = books.where((b) => b.lastOpenedAt != null).toList();

    // Sort by lastOpenedAt descending (most recent first)
    openedBooks.sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));

    return openedBooks.take(limit).toList();
  }

  /// Get books by category
  List<Book> getBooksByCategory(String category) {
    return _bookBox.values
        .where((b) => b.category?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get all categories
  List<String> getAllCategories() {
    final categories = _bookBox.values
        .where((b) => b.category != null)
        .map((b) => b.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}
