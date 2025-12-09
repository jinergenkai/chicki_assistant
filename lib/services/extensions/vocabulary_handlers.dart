import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:get/get.dart';

/// Extension for vocabulary related intent handlers
extension VocabularyHandlers on UnifiedIntentHandler {
  /// Sync flashcard context (system intent)
  Future<String> syncFlashCardContext(String? bookId) async {
    if (bookId == null) {
      return 'Error: Book ID required for context sync';
    }

    currentBookId = bookId;

    final vocabService = Get.find<VocabularyService>();
    await vocabService.init();

    currentVocabList = vocabService.getByBookId(bookId);
    currentCardIndex = 0;
    isCardFlipped = false;

    return 'Context synced: ${currentVocabList?.length ?? 0} vocabularies loaded';
  }

  /// Exit flashcard context (system intent)
  Future<String> exitFlashCardContext() async {
    currentBookId = null;
    currentVocabList = null;
    currentCardIndex = null;
    isCardFlipped = false;

    return 'Exited flashcard mode';
  }

  /// Handle review bookmarked intent
  Future<String> handleReviewBookmarked() async {
    final vocabService = Get.find<VocabularyService>();
    await vocabService.init();

    final bookmarkedVocabs = vocabService.getByTag('bookmarked');

    if (bookmarkedVocabs.isEmpty) {
      return 'No bookmarked words found';
    }

    currentVocabList = bookmarkedVocabs;
    currentCardIndex = 0;
    isCardFlipped = false;

    return 'Reviewing ${bookmarkedVocabs.length} bookmarked words';
  }

  /// Handle next vocab intent
  Future<String> handleNextVocab() async {
    currentCardIndex = (currentCardIndex ?? 0) + 1;
    return 'Next vocabulary card';
  }

  /// Handle read aloud intent
  Future<String> handleReadAloud() async {
    return 'Reading current vocabulary';
  }
}
