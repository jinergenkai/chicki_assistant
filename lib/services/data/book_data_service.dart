import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:get/get.dart';

/// GetX Service wrapper for BookService
/// Provides reactive state management and event handling
/// Used by both UI controllers and UnifiedIntentHandlerService
class BookDataService extends GetxService {
  late BookService _bookService;
  
  // Reactive state
  var books = <Book>[].obs;
  var currentBook = Rxn<Book>();
  var recentBooks = <Book>[].obs;
  var isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    logger.info('BookDataService: Initializing...');
    
    _bookService = BookService();
    await _bookService.init();
    
    logger.success('BookDataService: Initialized');
  }

  /// Load all books (static + custom)
  Future<void> loadBooks() async {
    try {
      isLoading.value = true;
      books.value = await _bookService.loadAllBooks();
      logger.info('BookDataService: Loaded ${books.length} books');
    } catch (e) {
      logger.error('BookDataService: Error loading books', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load recent books
  Future<void> loadRecentBooks({int limit = 5}) async {
    try {
      recentBooks.value = _bookService.getRecentBooks(limit: limit);
      logger.info('BookDataService: Loaded ${recentBooks.length} recent books');
    } catch (e) {
      logger.error('BookDataService: Error loading recent books', e);
      rethrow;
    }
  }

  /// Select a book by ID
  Future<Book?> selectBook(String bookId) async {
    try {
      final book = _bookService.getBook(bookId);
      if (book != null) {
        currentBook.value = book;
        await _bookService.markBookOpened(bookId);
        logger.info('BookDataService: Selected book: ${book.title}');
      } else {
        logger.warning('BookDataService: Book not found: $bookId');
      }
      return book;
    } catch (e) {
      logger.error('BookDataService: Error selecting book', e);
      rethrow;
    }
  }

  /// Get book by ID (without selecting)
  Book? getBook(String bookId) {
    return _bookService.getBook(bookId);
  }

  /// Create a new custom book
  Future<Book> createBook({
    required String title,
    required String description,
    String? ownerId,
    String? coverImagePath,
    String? author,
    String? category,
  }) async {
    try {
      final book = await _bookService.createNewBook(
        title: title,
        description: description,
        ownerId: ownerId,
        coverImagePath: coverImagePath,
        author: author,
        category: category,
      );
      
      // Add to books list
      books.add(book);
      logger.success('BookDataService: Created book: ${book.title}');
      
      return book;
    } catch (e) {
      logger.error('BookDataService: Error creating book', e);
      rethrow;
    }
  }

  /// Update a book
  Future<void> updateBook(Book book) async {
    try {
      await _bookService.updateBook(book);
      
      // Update in list
      final index = books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        books[index] = book;
      }
      
      // Update current if it's the same book
      if (currentBook.value?.id == book.id) {
        currentBook.value = book;
      }
      
      logger.info('BookDataService: Updated book: ${book.title}');
    } catch (e) {
      logger.error('BookDataService: Error updating book', e);
      rethrow;
    }
  }

  /// Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      await _bookService.deleteBook(bookId);
      
      // Remove from list
      books.removeWhere((b) => b.id == bookId);
      
      // Clear current if it's the same book
      if (currentBook.value?.id == bookId) {
        currentBook.value = null;
      }
      
      logger.info('BookDataService: Deleted book: $bookId');
    } catch (e) {
      logger.error('BookDataService: Error deleting book', e);
      rethrow;
    }
  }

  /// Get books by category
  List<Book> getBooksByCategory(String category) {
    return _bookService.getBooksByCategory(category);
  }

  /// Get all categories
  List<String> getAllCategories() {
    return _bookService.getAllCategories();
  }

  /// Clear current book selection
  void clearCurrentBook() {
    currentBook.value = null;
    logger.info('BookDataService: Cleared current book');
  }
}