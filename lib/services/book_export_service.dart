import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/vocabulary.dart';
import 'book_service.dart';
import 'vocabulary.service.dart';

/// Service for exporting and importing books with vocabulary data
class BookExportService {
  final BookService bookService;
  final VocabularyService vocabService;

  BookExportService({
    required this.bookService,
    required this.vocabService,
  });

  /// Export a book to JSON format (includes all vocabulary)
  Future<Map<String, dynamic>> exportBookToJson(String bookId) async {
    final book = bookService.getBook(bookId);
    if (book == null) {
      throw Exception('Book not found: $bookId');
    }

    // Get all non-deleted vocabularies sorted by orderIndex
    final vocabList = vocabService.getByBookIdSorted(bookId);

    return {
      'id': book.id,
      'title': book.title,
      'description': book.description,
      'price': book.price,
      'isCustom': book.isCustom,
      'ownerId': book.ownerId,
      'createdAt': book.createdAt?.toIso8601String(),
      'updatedAt': book.updatedAt?.toIso8601String(),
      'version': book.version ?? '1.0',
      'author': book.author,
      'category': book.category,
      'coverImagePath': book.coverImagePath,
      'isPublic': book.isPublic,

      // Export metadata
      'exportedAt': DateTime.now().toIso8601String(),
      'totalVocabCount': vocabList.length,

      // Vocabulary data
      'data': {
        'vocabList': vocabList.map((v) => v.toJson()).toList(),
      },
    };
  }

  /// Save book as JSON file to local storage
  Future<String> saveBookAsJsonFile(
    String bookId, {
    String? customPath,
  }) async {
    final json = await exportBookToJson(bookId);
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);

    final String filePath;
    if (customPath != null) {
      filePath = customPath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final book = bookService.getBook(bookId);
      final fileName = '${book?.title.replaceAll(' ', '_')}_$timestamp.json';
      filePath = '${directory.path}/exports/$fileName';
    }

    final file = File(filePath);

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Prepare book for sharing (export to temp + calculate hash)
  Future<Map<String, dynamic>> prepareBookForSharing(String bookId) async {
    // Export to temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final book = bookService.getBook(bookId);
    final fileName = 'book_${bookId}_$timestamp.json';
    final filePath = '${tempDir.path}/$fileName';

    await saveBookAsJsonFile(bookId, customPath: filePath);

    // Calculate SHA-256 hash for integrity verification
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();

    // Update book metadata with hash and public flag
    if (book != null) {
      book.jsonHash = hash;
      book.isPublic = true;
      book.updatedAt = DateTime.now();
      await bookService.updateBook(book);
    }

    return {
      'filePath': filePath,
      'hash': hash,
      'bookId': bookId,
      'fileName': fileName,
    };
  }

  /// Import book from JSON file
  Future<Book> importBookFromJson(String jsonPath) async {
    final file = File(jsonPath);

    if (!await file.exists()) {
      throw Exception('File not found: $jsonPath');
    }

    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    return await importBookFromJsonData(json);
  }

  /// Import book from JSON data (Map)
  Future<Book> importBookFromJsonData(Map<String, dynamic> json) async {
    // Generate new ID for imported book to avoid conflicts
    final now = DateTime.now();
    final newBookId = 'imported_${now.millisecondsSinceEpoch}';

    // Create book object
    final book = Book(
      id: newBookId,
      title: json['title'] ?? 'Imported Book',
      description: json['description'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as double? ?? 0.0),
      isCustom: true, // Imported books are always custom
      ownerId: null, // Will be set by caller if needed
      createdAt: now,
      updatedAt: now,
      version: json['version'] ?? '1.0',
      author: json['author'],
      category: json['category'],
      isPublic: false, // Not public by default
      // Note: coverImagePath is not imported, would need special handling
    );

    // Save book to database
    await bookService.addCustomBook(book);

    // Import vocabularies
    final vocabList = json['data']?['vocabList'] as List? ?? [];
    int orderIndex = 0;

    for (final vocabJson in vocabList) {
      try {
        final vocab = Vocabulary.fromJson(vocabJson as Map<String, dynamic>);

        // Override bookId to new imported book ID
        vocab.bookId = newBookId;
        vocab.id = null; // Clear ID to get new auto-increment
        vocab.orderIndex = orderIndex++;
        vocab.isSync = false;
        vocab.isDeleted = false;
        vocab.createdAt = now;
        vocab.updatedAt = now;

        await vocabService.upsertVocabulary(vocab);
      } catch (e) {
        // Skip invalid vocabulary entries
        print('Error importing vocabulary: $e');
      }
    }

    return book;
  }

  /// Verify JSON hash for integrity
  Future<bool> verifyBookHash(String filePath, String expectedHash) async {
    final file = File(filePath);

    if (!await file.exists()) {
      return false;
    }

    final bytes = await file.readAsBytes();
    final actualHash = sha256.convert(bytes).toString();

    return actualHash == expectedHash;
  }

  /// Export multiple books at once
  Future<String> exportMultipleBooks(
    List<String> bookIds, {
    String? outputDirectory,
  }) async {
    final directory = outputDirectory != null
        ? Directory(outputDirectory)
        : Directory('${(await getApplicationDocumentsDirectory()).path}/exports');

    await directory.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportDir = Directory('${directory.path}/export_$timestamp');
    await exportDir.create(recursive: true);

    for (final bookId in bookIds) {
      final book = bookService.getBook(bookId);
      if (book != null) {
        final fileName = '${book.title.replaceAll(' ', '_')}.json';
        final filePath = '${exportDir.path}/$fileName';
        await saveBookAsJsonFile(bookId, customPath: filePath);
      }
    }

    return exportDir.path;
  }

  /// Get export file size
  Future<int> getExportSize(String bookId) async {
    final json = await exportBookToJson(bookId);
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    return jsonString.length;
  }
}
