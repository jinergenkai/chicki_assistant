import 'dart:async';
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/book_bridge_service.dart';
import 'package:chicki_buddy/services/intent_bridge_service.dart';
import 'package:get/get.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BooksController extends GetxController {
  final RxList<Book> books = <Book>[].obs;
  final RxSet<String> downloadedBooks = <String>{}.obs;
  final RxString downloadingBookId = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isLoading = false.obs;
  
  // New: Observable for navigation requests from voice/UI intents
  final Rx<Book?> bookToNavigate = Rx<Book?>(null);

  final BookService service = BookService();
  final BookBridgeService bookBridgeService = BookBridgeService();
  
  StreamSubscription? _voiceActionSub;

  @override
  void onInit() {
    super.onInit();
    _setupEventListeners();
    loadBooksViaIntent();
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
        
      case 'navigateToBook':
        _handleNavigateToBookAction(data);
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

  void _handleNavigateToBookAction(Map<String, dynamic>? data) {
    if (data != null) {
      final bookId = data['bookId'] as String?;
      final bookName = data['bookName'] as String?;
      
      // Find book by ID or name
      Book? foundBook;
      if (bookId != null) {
        foundBook = books.firstWhereOrNull((b) => b.id == bookId);
      } else if (bookName != null) {
        foundBook = books.firstWhereOrNull(
          (b) => b.title.toLowerCase().contains(bookName.toLowerCase())
        );
      }
      
      if (foundBook != null) {
        // Update observable - BooksScreen will listen and handle navigation
        bookToNavigate.value = foundBook;
        logger.info('BooksController: Setting book to navigate: ${foundBook.title}');
      } else {
        logger.warning('BooksController: Book not found for navigation');
      }
    }
  }

  /// Load books via unified intent system (works for both UI and speech)
  Future<void> loadBooksViaIntent() async {
    isLoading.value = true;
    logger.info('BooksController: Requesting books via intent system');
    
    // Trigger intent in foreground isolate
    IntentBridgeService.triggerUIIntent(
      intent: 'listBook',
    );
    
    // Result will come back through event bus and update books list
  }

  /// Legacy method for direct loading (kept for compatibility)
  Future<void> reloadBooks() async {
    await loadBooksViaIntent();
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