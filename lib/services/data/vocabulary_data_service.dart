import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:get/get.dart';

/// GetX Service wrapper for VocabularyService
/// Provides reactive state management and event handling
/// Used by both UI controllers and UnifiedIntentHandlerService
class VocabularyDataService extends GetxService {
  late VocabularyService _vocabularyService;
  
  // Reactive state
  var vocabularies = <Vocabulary>[].obs;
  var currentVocab = Rxn<Vocabulary>();
  var currentBookVocabs = <Vocabulary>[].obs;
  var currentCardIndex = 0.obs;
  var isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    logger.info('VocabularyDataService: Initializing...');
    
    _vocabularyService = VocabularyService();
    await _vocabularyService.init();
    
    logger.success('VocabularyDataService: Initialized');
  }

  /// Load all vocabularies
  Future<void> loadAll({bool includeDeleted = false}) async {
    try {
      isLoading.value = true;
      vocabularies.value = _vocabularyService.getAll(includeDeleted: includeDeleted);
      logger.info('VocabularyDataService: Loaded ${vocabularies.length} vocabularies');
    } catch (e) {
      logger.error('VocabularyDataService: Error loading vocabularies', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load vocabularies for a specific book
  Future<void> loadByBookId(String bookId) async {
    try {
      isLoading.value = true;
      currentBookVocabs.value = _vocabularyService.getByBookIdSorted(bookId);
      currentCardIndex.value = 0;
      
      if (currentBookVocabs.isNotEmpty) {
        currentVocab.value = currentBookVocabs[0];
      } else {
        currentVocab.value = null;
      }
      
      logger.info('VocabularyDataService: Loaded ${currentBookVocabs.length} vocabs for book: $bookId');
    } catch (e) {
      logger.error('VocabularyDataService: Error loading book vocabularies', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to next card
  bool nextCard() {
    if (currentBookVocabs.isEmpty) {
      logger.warning('VocabularyDataService: No vocabularies loaded');
      return false;
    }
    
    if (currentCardIndex.value < currentBookVocabs.length - 1) {
      currentCardIndex.value++;
      currentVocab.value = currentBookVocabs[currentCardIndex.value];
      logger.info('VocabularyDataService: Next card ${currentCardIndex.value + 1}/${currentBookVocabs.length}');
      return true;
    } else {
      logger.info('VocabularyDataService: Already at last card');
      return false;
    }
  }

  /// Navigate to previous card
  bool prevCard() {
    if (currentBookVocabs.isEmpty) {
      logger.warning('VocabularyDataService: No vocabularies loaded');
      return false;
    }
    
    if (currentCardIndex.value > 0) {
      currentCardIndex.value--;
      currentVocab.value = currentBookVocabs[currentCardIndex.value];
      logger.info('VocabularyDataService: Prev card ${currentCardIndex.value + 1}/${currentBookVocabs.length}');
      return true;
    } else {
      logger.info('VocabularyDataService: Already at first card');
      return false;
    }
  }

  /// Go to specific card index
  bool goToCard(int index) {
    if (currentBookVocabs.isEmpty) {
      logger.warning('VocabularyDataService: No vocabularies loaded');
      return false;
    }
    
    if (index >= 0 && index < currentBookVocabs.length) {
      currentCardIndex.value = index;
      currentVocab.value = currentBookVocabs[index];
      logger.info('VocabularyDataService: Go to card ${index + 1}/${currentBookVocabs.length}');
      return true;
    } else {
      logger.warning('VocabularyDataService: Invalid card index: $index');
      return false;
    }
  }

  /// Add new vocabulary to a book
  Future<Vocabulary> addVocabToBook({
    required String word,
    required String meaning,
    required String bookId,
    String? topic,
    String? pronunciation,
    String? exampleSentence,
    String? exampleTranslation,
    int? difficulty,
  }) async {
    try {
      final vocab = await _vocabularyService.addVocabToBook(
        word: word,
        meaning: meaning,
        bookId: bookId,
        topic: topic,
        pronunciation: pronunciation,
        exampleSentence: exampleSentence,
        exampleTranslation: exampleTranslation,
        difficulty: difficulty,
      );
      
      // Add to current book vocabs if it matches
      if (currentBookVocabs.isNotEmpty && 
          currentBookVocabs.first.bookId == bookId) {
        currentBookVocabs.add(vocab);
      }
      
      logger.success('VocabularyDataService: Added vocab: $word');
      return vocab;
    } catch (e) {
      logger.error('VocabularyDataService: Error adding vocabulary', e);
      rethrow;
    }
  }

  /// Update vocabulary
  Future<void> updateVocab(Vocabulary vocab) async {
    try {
      await _vocabularyService.upsertVocabulary(vocab);
      
      // Update in current book vocabs
      final index = currentBookVocabs.indexWhere((v) => v.id == vocab.id);
      if (index != -1) {
        currentBookVocabs[index] = vocab;
      }
      
      // Update current if it's the same vocab
      if (currentVocab.value?.id == vocab.id) {
        currentVocab.value = vocab;
      }
      
      logger.info('VocabularyDataService: Updated vocab: ${vocab.word}');
    } catch (e) {
      logger.error('VocabularyDataService: Error updating vocabulary', e);
      rethrow;
    }
  }

  /// Delete vocabulary
  Future<void> deleteVocab(Vocabulary vocab) async {
    try {
      await _vocabularyService.deleteVocabulary(vocab);
      
      // Remove from current book vocabs
      currentBookVocabs.removeWhere((v) => v.id == vocab.id);
      
      // Clear current if it's the same vocab
      if (currentVocab.value?.id == vocab.id) {
        if (currentBookVocabs.isNotEmpty) {
          currentVocab.value = currentBookVocabs[currentCardIndex.value.clamp(0, currentBookVocabs.length - 1)];
        } else {
          currentVocab.value = null;
        }
      }
      
      logger.info('VocabularyDataService: Deleted vocab: ${vocab.word}');
    } catch (e) {
      logger.error('VocabularyDataService: Error deleting vocabulary', e);
      rethrow;
    }
  }

  /// Review vocabulary (SRS)
  Future<void> reviewVocab(Vocabulary vocab, int quality) async {
    try {
      await _vocabularyService.reviewVocabulary(vocab, quality);
      
      // Update in current book vocabs
      final index = currentBookVocabs.indexWhere((v) => v.id == vocab.id);
      if (index != -1) {
        currentBookVocabs[index] = vocab;
      }
      
      logger.info('VocabularyDataService: Reviewed vocab: ${vocab.word} with quality: $quality');
    } catch (e) {
      logger.error('VocabularyDataService: Error reviewing vocabulary', e);
      rethrow;
    }
  }

  /// Get vocabularies by tag
  List<Vocabulary> getByTag(String tag) {
    return _vocabularyService.getByTag(tag);
  }

  /// Get vocabularies due for review
  List<Vocabulary> getDueForReview(String bookId) {
    return _vocabularyService.getDueForReview(bookId);
  }

  /// Get vocabularies by review status
  List<Vocabulary> getByReviewStatus(String bookId, String status) {
    return _vocabularyService.getByReviewStatus(bookId, status);
  }

  /// Clear current vocabulary selection
  void clearCurrentVocab() {
    currentVocab.value = null;
    currentBookVocabs.clear();
    currentCardIndex.value = 0;
    logger.info('VocabularyDataService: Cleared current vocabulary');
  }
}