import 'dart:async';
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:get/get.dart';

class FlashCardController extends GetxController {
  final RxList<Vocabulary> vocabList = <Vocabulary>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isFlipped = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  final Book book;
  late VocabularyService _vocabularyService;
  late BookService _bookService;
  StreamSubscription? _voiceActionSub;

  FlashCardController({required this.book});

  @override
  void onInit() {
    super.onInit();
    _vocabularyService = Get.find<VocabularyService>();
    _bookService = Get.find<BookService>();

    _setupEventListeners();
    _markBookAsOpened(); // Track recent books
    loadVocabulary();
  }

  /// Mark book as opened for recent books tracking
  Future<void> _markBookAsOpened() async {
    try {
      await _bookService.markBookOpened(book.id);
      logger.info('FlashCardController: Marked book ${book.id} as opened');
    } catch (e) {
      logger.warning('FlashCardController: Failed to mark book as opened: $e');
    }
  }

  @override
  void onClose() {
    _voiceActionSub?.cancel();
    super.onClose();
  }

  void _setupEventListeners() {
    // Listen for voice action results from unified intent handler
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

    logger.info('FlashCardController: Handling voice action: $actionType');

    switch (actionType) {
      case 'nextCard':
        // Voice triggered nextCard - update UI
        nextCard();
        break;

      case 'prevCard':
        // Voice triggered prevCard - update UI
        prevCard();
        break;

      case 'flipCard':
        // Voice triggered flipCard - update UI
        flipCard();
        break;

      case 'toggleBookmark':
        // Voice triggered bookmark - reload current vocab
        if (vocabList.isNotEmpty) {
          loadVocabulary();
        }
        break;

      case 'error':
        if (data != null) {
          errorMessage.value = data['error'] as String? ?? 'Unknown error';
          logger.error('FlashCardController: Error - ${errorMessage.value}');
        }
        break;

      default:
        logger.info('FlashCardController: Unhandled action: $actionType');
    }
  }

  /// Load vocabulary for the book directly from service (UI action, no intent)
  Future<void> loadVocabulary() async {
    isLoading.value = true;
    errorMessage.value = null;
    logger.info('FlashCardController: Loading vocabulary for book ${book.id}');

    try {
      final vocabs = _vocabularyService.getByBookIdSorted(book.id);
      vocabList.value = vocabs;
      currentIndex.value = 0;
      isFlipped.value = false;
      isLoading.value = false;

      if (vocabList.isEmpty) {
        errorMessage.value = 'No vocabulary found for this book';
        logger.warning('FlashCardController: No vocabulary found for book ${book.id}');
      } else {
        errorMessage.value = null;
        logger.info('FlashCardController: Loaded ${vocabList.length} vocabularies');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load vocabulary: $e';
      isLoading.value = false;
      logger.error('FlashCardController: Error loading vocabulary', e);
    }
  }

  /// Navigate to next card (UI action, no intent needed)
  void nextCard() {
    if (vocabList.isEmpty) return;
    
    if (currentIndex.value < vocabList.length - 1) {
      currentIndex.value++;
      isFlipped.value = false;
      logger.info('FlashCardController: Next card ${currentIndex.value + 1}/${vocabList.length}');
    }
  }

  /// Navigate to previous card (UI action, no intent needed)
  void prevCard() {
    if (vocabList.isEmpty) return;
    
    if (currentIndex.value > 0) {
      currentIndex.value--;
      isFlipped.value = false;
      logger.info('FlashCardController: Prev card ${currentIndex.value + 1}/${vocabList.length}');
    }
  }

  /// Flip current card (UI action, no intent needed)
  void flipCard() {
    if (vocabList.isEmpty) return;
    
    isFlipped.value = !isFlipped.value;
    logger.info('FlashCardController: Flip card, isFlipped: ${isFlipped.value}');
  }

  /// Toggle bookmark for current card (UI action, no intent needed)
  Future<void> toggleBookmark() async {
    if (vocabList.isEmpty) return;

    final currentVocab = vocabList[currentIndex.value];
    final tags = currentVocab.tags ?? [];

    if (tags.contains('bookmarked')) {
      tags.remove('bookmarked');
    } else {
      tags.add('bookmarked');
    }

    await _vocabularyService.upsertVocabulary(currentVocab);
    logger.info('FlashCardController: Bookmark toggled for vocab ${currentVocab.word}');
  }

  /// Pronounce current word (UI action, handled by TTS service)
  Future<void> pronounceWord() async {
    if (vocabList.isEmpty) return;
    
    final currentVocab = vocabList[currentIndex.value];
    // TTS will be handled by TTSService, not via intent
    logger.info('FlashCardController: Pronounce word: ${currentVocab.word}');
  }

  /// Show example sentence (UI action)
  Future<void> showExample() async {
    if (vocabList.isEmpty) return;
    
    final currentVocab = vocabList[currentIndex.value];
    logger.info('FlashCardController: Show example for: ${currentVocab.word}');
  }

  /// Get current vocabulary
  Vocabulary? get currentVocab {
    if (vocabList.isEmpty || currentIndex.value >= vocabList.length) {
      return null;
    }
    return vocabList[currentIndex.value];
  }
}
