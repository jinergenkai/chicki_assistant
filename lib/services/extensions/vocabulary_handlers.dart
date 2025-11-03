import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/core/logger.dart';

/// Extension for vocabulary related intent handlers
extension VocabularyHandlers on UnifiedIntentHandler {
  /// Sync flashcard context without navigation (silent context update)
  /// Used when UI navigates to flashcard screen to sync handler state
  Future<Map<String, dynamic>> syncFlashCardContext(String? bookId, IntentSource source) async {
    if (bookId == null) {
      return createErrorResponse('syncFlashCardContext', 'Book ID is required', source);
    }

    logger.info('Syncing flashcard context for book: $bookId');

    // Update context silently
    currentBookId = bookId;

    // Load vocabulary list
    await vocabularyService.init();
    currentVocabList = vocabularyService.getByBookId(bookId);
    currentCardIndex = 0;
    isCardFlipped = false;

    logger.info('Context synced: ${currentVocabList?.length ?? 0} vocabularies loaded');

    // IMPORTANT: Return special marker to trigger node update
    return {
      'action': 'contextSynced',
      'data': {
        'bookId': bookId,
        'vocabCount': currentVocabList?.length ?? 0,
      },
      'requiresUI': false,
      '_forceNodeUpdate': 'vocab_session', // Force node transition
    };
  }

  /// Exit flashcard context and reset to book_context
  /// Used when UI navigates back from flashcard screen
  Future<Map<String, dynamic>> exitFlashCardContext(IntentSource source) async {
    logger.info('Exiting flashcard context');

    // Reset vocab context but keep book context
    currentVocabList = null;
    currentCardIndex = null;
    isCardFlipped = false;
    // Keep currentBookId if still in book screen

    return {
      'action': 'contextReset',
      'data': {},
      'requiresUI': false,
      '_forceNodeUpdate': 'book_context', // Go back to book_context
    };
  }
  /// Handle next vocabulary intent
  Future<Map<String, dynamic>> handleNextVocab(IntentSource source) async {
    currentCardIndex = (currentCardIndex ?? 0) + 1;

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Next vocabulary card',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'showCard',
        'data': {'cardIndex': currentCardIndex},
        'requiresUI': true,
      };
    }
  }

  /// Handle read aloud intent
  Future<Map<String, dynamic>> handleReadAloud(IntentSource source) async {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Reading current vocabulary',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'readAloud',
        'data': {'cardIndex': currentCardIndex},
        'requiresUI': true,
      };
    }
  }

  /// Handle review bookmarked intent
  Future<Map<String, dynamic>> handleReviewBookmarked(IntentSource source) async {
    await vocabularyService.init();
    final bookmarkedVocabs = vocabularyService.getByTag('bookmarked');

    if (bookmarkedVocabs.isEmpty) {
      if (source == IntentSource.speech) {
        return {
          'action': 'speak',
          'text': 'No bookmarked words found',
          'requiresUI': false,
        };
      } else {
        return {
          'action': 'error',
          'data': {'message': 'No bookmarked words'},
          'requiresUI': true,
        };
      }
    }

    // Set bookmarked list as current vocab list
    currentVocabList = bookmarkedVocabs;
    currentCardIndex = 0;
    isCardFlipped = false;

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Reviewing ${bookmarkedVocabs.length} bookmarked words',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'loadVocabulary',
        'data': {
          'vocabularies': bookmarkedVocabs.map((v) => v.toJson()).toList(),
          'currentIndex': currentCardIndex,
          'isBookmarkedReview': true,
        },
        'requiresUI': true,
      };
    }
  }
}
