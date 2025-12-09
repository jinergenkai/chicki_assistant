import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:get/get.dart';

/// Extension for flash card related intent handlers
extension FlashCardHandlers on UnifiedIntentHandler {
  /// Handle next card intent
  Future<String> handleNextCard() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    if (index >= currentVocabList!.length - 1) {
      return 'You are already at the last card';
    }

    currentCardIndex = index + 1;
    isCardFlipped = false;
    final currentVocab = currentVocabList![currentCardIndex!];

    // Emit event for UI update
    eventBus.emit(AppEvent(
      AppEventType.voiceAction,
      {
        'action': 'nextCard',
        'data': {
          'currentIndex': currentCardIndex,
          'vocabulary': currentVocab.toJson(),
          'isFlipped': isCardFlipped,
        },
      },
    ));

    return 'Next card: ${currentVocab.word}';
  }

  /// Handle previous card intent
  Future<String> handlePrevCard() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    if (index <= 0) {
      return 'You are already at the first card';
    }

    currentCardIndex = index - 1;
    isCardFlipped = false;
    final currentVocab = currentVocabList![currentCardIndex!];

    // Emit event for UI update
    eventBus.emit(AppEvent(
      AppEventType.voiceAction,
      {
        'action': 'prevCard',
        'data': {
          'currentIndex': currentCardIndex,
          'vocabulary': currentVocab.toJson(),
          'isFlipped': isCardFlipped,
        },
      },
    ));

    return 'Previous card: ${currentVocab.word}';
  }

  /// Handle flip card intent
  Future<String> handleFlipCard() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];

    isCardFlipped = !isCardFlipped;

    // Emit event for UI update
    eventBus.emit(AppEvent(
      AppEventType.voiceAction,
      {
        'action': 'flipCard',
        'data': {
          'isFlipped': isCardFlipped,
          'vocabulary': currentVocab.toJson(),
        },
      },
    ));

    final text = isCardFlipped
        ? 'Meaning: ${currentVocab.meaning ?? "No meaning available"}'
        : 'Word: ${currentVocab.word}';
    return text;
  }

  /// Handle pronounce word intent
  Future<String> handlePronounceWord() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];

    // TODO: Integrate with TTS service to pronounce with proper phonetics
    return currentVocab.word;
  }

  /// Handle repeat word intent
  Future<String> handleRepeatWord() async {
    return await handlePronounceWord();
  }

  /// Handle example sentence intent
  Future<String> handleExampleSentence() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];
    final example =
        currentVocab.exampleSentence ?? 'No example sentence available';

    return 'Example: $example';
  }

  /// Handle translate word intent
  Future<String> handleTranslateWord() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];
    final meaning = currentVocab.meaning ?? 'No translation available';

    return 'Translation: $meaning';
  }

  /// Handle spell word intent
  Future<String> handleSpellWord() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];
    final letters = currentVocab.word.split('').join(', ');

    return 'Spelling: $letters';
  }

  /// Handle bookmark word intent
  Future<String> handleBookmarkWord() async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return 'Sorry, no vocabulary loaded';
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];

    // Toggle bookmark
    final tags = currentVocab.tags ?? [];
    final isBookmarked = tags.contains('bookmarked');

    if (isBookmarked) {
      tags.remove('bookmarked');
    } else {
      tags.add('bookmarked');
    }
    currentVocab.tags = tags;

    final vocabService = Get.find<VocabularyService>();
    await vocabService.upsertVocabulary(currentVocab);

    // Emit event for UI update
    eventBus.emit(AppEvent(
      AppEventType.voiceAction,
      {
        'action': 'toggleBookmark',
        'data': {
          'isBookmarked': !isBookmarked,
          'vocabulary': currentVocab.toJson(),
        },
      },
    ));

    return isBookmarked ? 'Bookmark removed' : 'Word bookmarked';
  }
}
