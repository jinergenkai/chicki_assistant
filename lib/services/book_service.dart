import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import '../models/book.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';

class BookService {
  static const String boxName = "bookBox";
  late Box<Book> _bookBox;

  // BookService(this._bookBox);

  Future<void> init() async {
    _bookBox = await Hive.openBox<Book>(boxName);
  }

  /// Load static books from assets (JSON)
  Future<List<Book>> loadStaticBooks() async {
    final data = await rootBundle.loadString('assets/vocab/books.json');
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Book(
      id: e['id'],
      title: e['title'],
      description: e['description'],
      price: (e['price'] is int) ? (e['price'] as int).toDouble() : e['price'],
      isCustom: e['isCustom'] ?? false,
      ownerId: e['ownerId'],
      topics: (e['topics'] as List<dynamic>).map((t) => Topic(
        id: t['id'],
        title: t['title'],
        vocabList: (t['vocabList'] as List<dynamic>).map((v) => Vocabulary(
          word: v['word'],
          originLanguage: v['originLanguage'],
          targetLanguage: v['targetLanguage'],
          meaning: v['meaning'],
          exampleSentence: v['example'],
          ttsAudioPath: v['audioUrl'],
          createdAt: DateTime.parse(v['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(v['updatedAt'] ?? DateTime.now().toIso8601String()),
        )).toList(),
        bookId: t['bookId'],
      )).toList(),
    )).toList();
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
}