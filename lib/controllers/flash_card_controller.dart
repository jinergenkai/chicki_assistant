import 'dart:async';
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/intent_bridge_service.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
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
  final VocabularyService _vocabularyService = VocabularyService();
  StreamSubscription? _voiceActionSub;

  FlashCardController({required this.book});

  @override
  void onInit() {
    super.onInit();
    _setupEventListeners();
    loadVocabularyViaIntent();
    _syncContextWithHandler();
  }

  @override
  void onClose() {
    _voiceActionSub?.cancel();
    _resetHandlerContext();
    super.onClose();
  }

  /// Sync context with intent handler when entering flashcard screen
  /// This allows voice commands to work properly in flashcard context
  void _syncContextWithHandler() {
    logger.info('FlashCardController: Syncing context with handler for book ${book.id}');

    // Send a "context sync" intent (doesn't trigger navigation)
    // This updates handler's currentBookId, currentVocabList, etc.
    IntentBridgeService.triggerUIIntent(
      intent: 'syncFlashCardContext',
      slots: {
        'bookId': book.id,
        'silent': true, // Don't return requiresUI
      },
    );
  }

  /// Reset handler context when leaving flashcard screen
  void _resetHandlerContext() {
    logger.info('FlashCardController: Resetting handler context');

    IntentBridgeService.triggerUIIntent(
      intent: 'exitFlashCard',
    );
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
      case 'selectBook':
      case 'loadVocabulary':
        if (data != null && data['vocabularies'] != null) {
          final vocabs = (data['vocabularies'] as List)
              .map((v) => Vocabulary.fromJson(v as Map<String, dynamic>))
              .toList();
          vocabList.value = vocabs;
          currentIndex.value = data['currentIndex'] as int? ?? 0;
          isLoading.value = false;
          isFlipped.value = false;

          if (vocabs.isEmpty) {
            errorMessage.value = 'No vocabulary found for this book';
          } else {
            errorMessage.value = null;
          }

          logger.info('FlashCardController: Loaded ${vocabs.length} vocabularies');
        }
        break;

      case 'nextCard':
        if (data != null) {
          currentIndex.value = data['currentIndex'] as int;
          isFlipped.value = data['isFlipped'] as bool? ?? false;
          logger.info('FlashCardController: Next card, index: ${currentIndex.value}');
        }
        break;

      case 'prevCard':
        if (data != null) {
          currentIndex.value = data['currentIndex'] as int;
          isFlipped.value = data['isFlipped'] as bool? ?? false;
          logger.info('FlashCardController: Prev card, index: ${currentIndex.value}');
        }
        break;

      case 'flipCard':
        if (data != null) {
          isFlipped.value = data['isFlipped'] as bool;
          logger.info('FlashCardController: Flip card, isFlipped: ${isFlipped.value}');
        }
        break;

      case 'toggleBookmark':
        if (data != null && data['vocabulary'] != null) {
          final updatedVocab = Vocabulary.fromJson(data['vocabulary'] as Map<String, dynamic>);
          final index = vocabList.indexWhere((v) => v.id == updatedVocab.id);
          if (index != -1) {
            vocabList[index] = updatedVocab;
            logger.info('FlashCardController: Bookmark toggled for vocab ${updatedVocab.word}');
          }
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

  /// Load vocabulary for the book directly from service
  /// (UI navigation already happened, no need to trigger selectBook intent)
  Future<void> loadVocabularyViaIntent() async {
    isLoading.value = true;
    errorMessage.value = null;
    logger.info('FlashCardController: Loading vocabulary for book ${book.id} directly');

    try {
      await _vocabularyService.init();
      final vocabs = _vocabularyService.getByBookId(book.id);

      vocabList.value = vocabs;
      currentIndex.value = 0;
      isFlipped.value = false;
      isLoading.value = false;

      if (vocabs.isEmpty) {
        errorMessage.value = 'No vocabulary found for this book';
        logger.warning('FlashCardController: No vocabulary found for book ${book.id}');
      } else {
        errorMessage.value = null;
        logger.info('FlashCardController: Loaded ${vocabs.length} vocabularies');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load vocabulary: $e';
      isLoading.value = false;
      logger.error('FlashCardController: Error loading vocabulary', e);
    }
  }

  /// Navigate to next card via intent
  Future<void> nextCard() async {
    if (vocabList.isEmpty) return;

    logger.info('FlashCardController: Triggering nextCard intent');
    await IntentBridgeService.triggerUIIntent(
      intent: 'nextCard',
    );
  }

  /// Navigate to previous card via intent
  Future<void> prevCard() async {
    if (vocabList.isEmpty) return;

    logger.info('FlashCardController: Triggering prevCard intent');
    await IntentBridgeService.triggerUIIntent(
      intent: 'prevCard',
    );
  }

  /// Flip current card via intent
  Future<void> flipCard() async {
    if (vocabList.isEmpty) return;

    logger.info('FlashCardController: Triggering flipCard intent');
    await IntentBridgeService.triggerUIIntent(
      intent: 'flipCard',
    );
  }

  /// Toggle bookmark for current card via intent
  Future<void> toggleBookmark() async {
    if (vocabList.isEmpty) return;

    logger.info('FlashCardController: Triggering bookmarkWord intent');
    await IntentBridgeService.triggerUIIntent(
      intent: 'bookmarkWord',
    );
  }

  /// Pronounce current word via intent
  Future<void> pronounceWord() async {
    if (vocabList.isEmpty) return;

    logger.info('FlashCardController: Triggering pronounceWord intent');
    await IntentBridgeService.triggerUIIntent(
      intent: 'pronounceWord',
    );
  }

  /// Show example sentence via intent
  Future<void> showExample() async {
    if (vocabList.isEmpty) return;

    logger.info('FlashCardController: Triggering exampleSentence intent');
    await IntentBridgeService.triggerUIIntent(
      intent: 'exampleSentence',
    );
  }

  /// Get current vocabulary
  Vocabulary? get currentVocab {
    if (vocabList.isEmpty || currentIndex.value >= vocabList.length) {
      return null;
    }
    return vocabList[currentIndex.value];
  }
}
