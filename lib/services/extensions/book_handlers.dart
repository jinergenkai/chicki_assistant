import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/services/utils/text_matcher.dart';
import 'package:chicki_buddy/core/logger.dart';

/// Extension for book and topic related intent handlers
extension BookHandlers on UnifiedIntentHandler {
  /// Handle list book intent
  Future<Map<String, dynamic>> handleListBook(IntentSource source) async {
    await bookService.init();
    final books = await bookService.loadAllBooks();

    // Store books list for number-based selection
    currentBooksList = books;

    if (source == IntentSource.speech) {
      // Speech: Numbered list for easy selection
      final booksList = <String>[];
      for (int i = 0; i < books.length; i++) {
        final book = books[i];
        final bookName = book.title ?? book.id ?? 'Book ${i + 1}';
        booksList.add('${i + 1}. $bookName');
      }

      final booksText = booksList.join(', ');
      return {
        'action': 'speak',
        'text': 'We have ${books.length} books: $booksText. Please say the number or name of the book you want to choose.',
        'requiresUI': false,
      };
    } else {
      // UI: Full data for display
      return {
        'action': 'listBook',
        'data': {'books': books.map((b) => b.toJson()).toList()},
        'requiresUI': true,
      };
    }
  }

  /// Handle select book intent
  /// - UI: Direct bookId match (exact)
  /// - Speech: Fuzzy matching for numbers/names (handles SST errors)
  Future<Map<String, dynamic>> handleSelectBook(String? bookIdOrName, IntentSource source) async {
    if (bookIdOrName == null) {
      return createErrorResponse('selectBook', 'Book ID or name is required', source);
    }

    String? actualBookId;
    String? actualBookName;
    dynamic selectedBook;

    // === UI Source: Direct ID lookup (no fuzzy needed) ===
    if (source == IntentSource.ui) {
      logger.info('UI selection: trying direct bookId lookup for "$bookIdOrName"');

      // Try to find book by exact ID first
      await bookService.init();
      final allBooks = await bookService.loadAllBooks();
      selectedBook = allBooks.cast<dynamic?>().firstWhere(
        (book) => book?.id == bookIdOrName,
        orElse: () => null,
      );

      if (selectedBook != null) {
        actualBookId = selectedBook.id;
        actualBookName = selectedBook.title ?? selectedBook.name ?? selectedBook.id;
        logger.info('Found book by ID: $actualBookId');
      } else {
        logger.warning('Book with ID "$bookIdOrName" not found');
        return createErrorResponse('selectBook', 'Book not found: $bookIdOrName', source);
      }
    }
    // === Speech Source: Fuzzy matching ===
    else {
      if (currentBooksList == null || currentBooksList!.isEmpty) {
        // Try to load books if not available
        await bookService.init();
        currentBooksList = await bookService.loadAllBooks();
      }

      if (currentBooksList == null || currentBooksList!.isEmpty) {
        return createErrorResponse('selectBook', 'No books available. Please list books first.', source);
      }

      // Step 1: Try to extract number (handles "one", "two", "too", "number 2", etc.)
      final number = TextMatcher.extractNumber(bookIdOrName);
      if (number != null && number > 0 && number <= currentBooksList!.length) {
        // Valid number selection
        selectedBook = currentBooksList![number - 1];
        actualBookId = selectedBook.id;
        actualBookName = selectedBook.title ?? selectedBook.id;
        logger.info('Selected book by number $number: $actualBookName');
      }

      // Step 2: If no valid number, use fuzzy matching on book names
      if (selectedBook == null) {
        logger.info('No valid number found, trying fuzzy match for: "$bookIdOrName"');

        final match = TextMatcher.findBestMatch(
          bookIdOrName,
          currentBooksList!,
          (book) => book.title ?? book.name ?? book.id ?? '',
        );

        if (match != null && match.score >= 0.3) {
          selectedBook = match.item;
          actualBookId = selectedBook.id;
          actualBookName = selectedBook.title ?? selectedBook.name ?? selectedBook.id;
          logger.info('Selected book by fuzzy match (score=${match.score.toStringAsFixed(2)}): $actualBookName');
        } else {
          // No good match found
          logger.warning('No matching book found for: "$bookIdOrName"');
          return createErrorResponse(
            'selectBook',
            'Could not find book matching "$bookIdOrName". Please try again with a number or book name.',
            source,
          );
        }
      }
    }

    currentBookId = actualBookId;

    // Load vocabulary list for this book
    await vocabularyService.init();
    currentVocabList = vocabularyService.getByBookId(actualBookId!);
    currentCardIndex = 0;
    isCardFlipped = false;

    logger.info('Loaded ${currentVocabList?.length ?? 0} vocabularies for book $actualBookId');

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Opening $actualBookName with ${currentVocabList?.length ?? 0} vocabulary cards',
        'requiresUI': false,
      };
    } else {
      // Return 'selectBook' action for BooksController to handle navigation
      // Also include vocabulary data for FlashCardController
      return {
        'action': 'selectBook',
        'data': {
          'bookId': actualBookId,
          'bookName': actualBookName,
          'vocabularies': currentVocabList?.map((v) => v.toJson()).toList() ?? [],
          'currentIndex': currentCardIndex,
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle list topic intent
  Future<Map<String, dynamic>> handleListTopic(IntentSource source) async {
    if (currentBookId == null) {
      return createErrorResponse('listTopic', 'No book selected', source);
    }

    // Simulate topic loading
    final topics = ['Animals', 'Colors', 'Numbers', 'Family'];

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Available topics: ${topics.join(', ')}',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'listTopic',
        'data': {'bookId': currentBookId, 'topics': topics},
        'requiresUI': true,
      };
    }
  }
}
