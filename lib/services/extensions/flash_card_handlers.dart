import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:get/get.dart';

/// Extension for flash card related intent handlers
extension FlashCardHandlers on UnifiedIntentHandler {
  /// Handle next card intent
  Future<Map<String, dynamic>> handleNextCard(IntentSource source) async {
    // Use currentVocabList from UnifiedIntentHandler state
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('nextCard', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    if (index >= currentVocabList!.length - 1) {
      return createErrorResponse('nextCard', 'Already at last card', source);
    }

    currentCardIndex = index + 1;
    isCardFlipped = false;
    final currentVocab = currentVocabList![currentCardIndex!];
    
    // Emit event for voice action
    if (source == IntentSource.speech) {
      eventBus.emit(AppEvent(
        AppEventType.voiceAction,
        {
          'action': 'nextCard',
          'data': {
            'currentIndex': currentCardIndex,
            'vocabulary': currentVocab.toJson(),
          },
        },
      ));
    }

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Next card: ${currentVocab.word}',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'nextCard',
        'data': {
          'currentIndex': currentCardIndex,
          'vocabulary': currentVocab.toJson(),
          'isFlipped': isCardFlipped,
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle previous card intent
  Future<Map<String, dynamic>> handlePrevCard(IntentSource source) async {
    // Use currentVocabList from UnifiedIntentHandler state
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('prevCard', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    if (index <= 0) {
      return createErrorResponse('prevCard', 'Already at first card', source);
    }

    currentCardIndex = index - 1;
    isCardFlipped = false;
    final currentVocab = currentVocabList![currentCardIndex!];
    
    // Emit event for voice action
    if (source == IntentSource.speech) {
      eventBus.emit(AppEvent(
        AppEventType.voiceAction,
        {
          'action': 'prevCard',
          'data': {
            'currentIndex': currentCardIndex,
            'vocabulary': currentVocab.toJson(),
          },
        },
      ));
    }

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Previous card: ${currentVocab.word}',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'prevCard',
        'data': {
          'currentIndex': currentCardIndex,
          'vocabulary': currentVocab.toJson(),
          'isFlipped': isCardFlipped,
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle flip card intent
  Future<Map<String, dynamic>> handleFlipCard(IntentSource source) async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('flipCard', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];

    isCardFlipped = !isCardFlipped;
    
    // Emit event for voice action
    if (source == IntentSource.speech) {
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
    }

    if (source == IntentSource.speech) {
      final text = isCardFlipped
          ? 'Meaning: ${currentVocab.meaning ?? "No meaning available"}'
          : 'Word: ${currentVocab.word}';
      return {
        'action': 'speak',
        'text': text,
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'flipCard',
        'data': {
          'isFlipped': isCardFlipped,
          'vocabulary': currentVocab.toJson(),
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle pronounce word intent
  Future<Map<String, dynamic>> handlePronounceWord(IntentSource source) async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('pronounceWord', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];

    // TODO: Integrate with TTS service to pronounce the word
    return {
      'action': 'pronounce',
      'text': currentVocab.word,
      'data': {
        'word': currentVocab.word,
        'pronunciation': currentVocab.pronunciation,
      },
      'requiresUI': false,
    };
  }

  /// Handle repeat word intent
  Future<Map<String, dynamic>> handleRepeatWord(IntentSource source) async {
    // Same as pronounceWord for now
    return await handlePronounceWord(source);
  }

  /// Handle example sentence intent
  Future<Map<String, dynamic>> handleExampleSentence(IntentSource source) async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('exampleSentence', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];
    final example = currentVocab.exampleSentence ?? 'No example sentence available';

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Example: $example',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'showExample',
        'data': {
          'example': example,
          'vocabulary': currentVocab.toJson(),
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle translate word intent
  Future<Map<String, dynamic>> handleTranslateWord(IntentSource source) async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('translateWord', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];
    final meaning = currentVocab.meaning ?? 'No translation available';

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Translation: $meaning',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'showTranslation',
        'data': {
          'meaning': meaning,
          'vocabulary': currentVocab.toJson(),
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle spell word intent
  Future<Map<String, dynamic>> handleSpellWord(IntentSource source) async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('spellWord', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];
    final letters = currentVocab.word.split('').join(', ');

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Spelling: $letters',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'showSpelling',
        'data': {
          'word': currentVocab.word,
          'letters': letters,
        },
        'requiresUI': true,
      };
    }
  }

  /// Handle bookmark word intent
  Future<Map<String, dynamic>> handleBookmarkWord(IntentSource source) async {
    if (currentVocabList == null || currentVocabList!.isEmpty) {
      return createErrorResponse('bookmarkWord', 'No vocabulary loaded', source);
    }

    final index = currentCardIndex ?? 0;
    final currentVocab = currentVocabList![index];

    // Toggle bookmark (add 'bookmarked' tag)
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
    
    // Emit event for voice action
    if (source == IntentSource.speech) {
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
    }

    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': isBookmarked ? 'Bookmark removed' : 'Word bookmarked',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'toggleBookmark',
        'data': {
          'isBookmarked': !isBookmarked,
          'vocabulary': currentVocab.toJson(),
        },
        'requiresUI': true,
      };
    }
  }
}
