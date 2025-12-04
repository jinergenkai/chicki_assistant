import 'dart:async';
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/core/app_router.dart';
import 'package:chicki_buddy/ui/screens/flash_card_screen2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/book.dart';
import '../services/data/book_data_service.dart';

class BooksController extends GetxController {
  final RxList<Book> books = <Book>[].obs;
  final RxSet<String> downloadedBooks = <String>{}.obs;
  final RxString downloadingBookId = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isLoading = false.obs;
  
  // New: Observable for navigation requests from voice/UI intents
  final Rx<Book?> bookToNavigate = Rx<Book?>(null);

  late BookDataService bookDataService;
  
  StreamSubscription? _voiceActionSub;

  @override
  void onInit() {
    super.onInit();
    bookDataService = Get.find<BookDataService>();
    _setupEventListeners();
    loadBooks();
  }
  
  @override
  void onClose() {
    _voiceActionSub?.cancel();
    super.onClose();
  }

  void _setupEventListeners() {
    // Listen for voice action results from unified intent handler
    // ALL voice/intent logic centralized here
    _voiceActionSub = eventBus.stream
        .where((event) => event.type == AppEventType.voiceAction)
        .listen((event) {
      final action = event.payload as Map<String, dynamic>;
      _handleVoiceAction(action);
    });
  }

  void _handleVoiceAction(Map<String, dynamic> action) {
    final actionType = action['action'] as String?;
    final data = action['data'] as Map<String, dynamic>?;
    
    logger.info('BooksController: Handling voice action: $actionType');
    
    switch (actionType) {
      case 'listBook':
        _handleListBookAction(data);
        break;
        
      case 'selectBook':
        _handleSelectBookAction(data);
        break;
        
      default:
        logger.info('BooksController: Unhandled action: $actionType');
    }
  }

  void _handleListBookAction(Map<String, dynamic>? data) {
    if (data != null && data['books'] != null) {
      final booksList = (data['books'] as List)
          .map((b) => Book.fromJson(b as Map<String, dynamic>))
          .toList();
      books.value = booksList;
      isLoading.value = false;
      logger.info('BooksController: Updated books list with ${booksList.length} books');
    }
  }

  void _handleSelectBookAction(Map<String, dynamic>? data) async {
    if (data != null) {
      final bookId = data['bookId'] as String?;
      final bookName = data['bookName'] as String?;

      // If books list is empty, load it first (for voice commands from non-books screen)
      if (books.isEmpty) {
        logger.info('BooksController: Books list empty, loading via BookDataService...');
        await bookDataService.loadBooks();
        books.value = bookDataService.books;
        logger.info('BooksController: Loaded ${books.length} books');
      }

      // Find book by ID or name
      Book? foundBook;
      if (bookId != null) {
        foundBook = bookDataService.getBook(bookId);
        foundBook ??= books.firstWhereOrNull((b) => b.id == bookId);
      } else if (bookName != null) {
        foundBook = books.firstWhereOrNull(
          (b) => b.title.toLowerCase().contains(bookName.toLowerCase())
        );
      }

      if (foundBook != null) {
        // Update observable for BooksScreen (if mounted)
        bookToNavigate.value = foundBook;

        // Also navigate directly using global navigatorKey (for voice from any screen)
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          logger.info('BooksController: Navigating to FlashCard for book: ${foundBook.title}');
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FlashCardScreen2(book: foundBook!),
          ));
        } else {
          logger.warning('BooksController: Navigator context not available');
        }
      } else {
        logger.warning('BooksController: Book not found for navigation (bookId: $bookId, bookName: $bookName)');
      }
    }
  }

  /// Load books using BookDataService (direct, no intent needed for UI)
  Future<void> loadBooks() async {
    isLoading.value = true;
    logger.info('BooksController: Loading books via BookDataService...');
    
    try {
      await bookDataService.loadBooks();
      books.value = bookDataService.books;
      isLoading.value = false;
      logger.success('BooksController: Loaded ${books.length} books');
    } catch (e) {
      logger.error('BooksController: Error loading books', e);
      isLoading.value = false;
    }
  }

  /// Reload books (for UI refresh)
  Future<void> reloadBooks() async {
    await loadBooks();
  }

  void downloadBook(String bookId) async {
    downloadingBookId.value = bookId;
    downloadProgress.value = 0.0;
    // Simulate download progress
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      downloadProgress.value = i / 10.0;
    }
    downloadedBooks.add(bookId);
    downloadingBookId.value = '';
    downloadProgress.value = 0.0;
  }

  void removeBook(String bookId) {
    downloadedBooks.remove(bookId);
  }
}