import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/services/utils/text_matcher.dart';
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';

/// Extension for book and topic related intent handlers
extension BookHandlers on UnifiedIntentHandler {
  /// Handle list book intent
  Future<String> handleListBook() async {
    final bookService = Get.find<BookService>();
    final books = await bookService.loadAllBooks();

    currentBooksList = books;

    // Emit event for UI update
    eventBus.emit(AppEvent(
      AppEventType.voiceAction,
      {
        'action': 'listBook',
        'data': {'books': books.map((b) => b.toJson()).toList()},
      },
    ));

    // Build speech text
    final booksList = <String>[];
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      final bookName = book.title ?? book.id ?? 'Book ${i + 1}';
      booksList.add('${i + 1}. $bookName');
    }

    final booksText = booksList.join(', ');
    return 'We have ${books.length} books: $booksText. Please say the number or name of the book you want to choose.';
  }

  /// Handle select book intent with fuzzy matching
  Future<String> handleSelectBook(String? bookIdOrName) async {
    if (bookIdOrName == null) {
      return 'Sorry, please specify which book you want to open';
    }

    final bookService = Get.find<BookService>();
    final vocabService = Get.find<VocabularyService>();

    // Load books if not available
    if (currentBooksList == null || currentBooksList!.isEmpty) {
      currentBooksList = await bookService.loadAllBooks();
    }

    if (currentBooksList == null || currentBooksList!.isEmpty) {
      return 'Sorry, no books available. Please add some books first.';
    }

    String? actualBookId;
    String? actualBookName;
    dynamic selectedBook;

    // Try extract number first
    final number = TextMatcher.extractNumber(bookIdOrName);
    if (number != null && number > 0 && number <= currentBooksList!.length) {
      selectedBook = currentBooksList![number - 1];
      actualBookId = selectedBook.id;
      actualBookName = selectedBook.title ?? selectedBook.id;
      logger.info('Selected book by number $number: $actualBookName');
    }

    // Fuzzy match on names
    if (selectedBook == null) {
      logger.info('Trying fuzzy match for: "$bookIdOrName"');
      final match = TextMatcher.findBestMatch(
        bookIdOrName,
        currentBooksList!,
        (book) => book.title ?? book.name ?? book.id ?? '',
      );

      if (match != null && match.score >= 0.3) {
        selectedBook = match.item;
        actualBookId = selectedBook.id;
        actualBookName =
            selectedBook.title ?? selectedBook.name ?? selectedBook.id;
        logger.info('Selected book by fuzzy match: $actualBookName');
      } else {
        return 'Sorry, I could not find a book matching "$bookIdOrName". Please try again.';
      }
    }

    currentBookId = actualBookId;
    currentVocabList = vocabService.getByBookIdSorted(actualBookId!);
    currentCardIndex = 0;
    isCardFlipped = false;

    logger.info('Loaded ${currentVocabList?.length ?? 0} vocabularies');

    // Emit event for navigation
    eventBus.emit(AppEvent(
      AppEventType.voiceAction,
      {
        'action': 'selectBook',
        'data': {
          'bookId': actualBookId,
          'bookName': actualBookName,
          'vocabularies':
              currentVocabList?.map((v) => v.toJson()).toList() ?? [],
          'currentIndex': currentCardIndex,
        },
      },
    ));

    return 'Opening $actualBookName with ${currentVocabList?.length ?? 0} vocabulary cards';
  }

  /// Handle list topic intent
  Future<String> handleListTopic() async {
    if (currentBookId == null) {
      return 'Sorry, please select a book first';
    }

    final topics = ['Animals', 'Colors', 'Numbers', 'Family'];
    return 'Available topics: ${topics.join(', ')}';
  }
}
