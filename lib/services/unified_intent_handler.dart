import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:chicki_buddy/voice/graph/intent_node.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/core/logger.dart';

// Import all intent handler extensions
import 'extensions/flash_card_handlers.dart';
import 'extensions/book_handlers.dart';
import 'extensions/vocabulary_handlers.dart';
import 'extensions/conversation_handlers.dart';
import 'extensions/general_handlers.dart';

/// Unified handler for voice intents
/// Simplified: Returns String (TTS text) directly
class UnifiedIntentHandler {
  final WorkflowGraph workflowGraph;
  final BookService bookService;
  final VocabularyService vocabularyService;

  /// Current node in workflow (context tracking)
  String _currentNodeId;

  /// Current state for context
  String? currentBookId;
  String? currentTopicId;
  int? currentCardIndex;
  List<Vocabulary>? currentVocabList;
  bool isCardFlipped = false;

  /// Store current books list for number-based selection
  List<dynamic>? currentBooksList;

  UnifiedIntentHandler({
    required this.workflowGraph,
    BookService? bookService,
    VocabularyService? vocabularyService,
    String? initialNodeId,
  })  : bookService = bookService ?? BookService(),
        vocabularyService = vocabularyService ?? VocabularyService(),
        _currentNodeId = initialNodeId ?? 'root';

  /// Get current node
  IntentNode? get currentNode => workflowGraph.nodes[_currentNodeId];

  /// Get current node ID
  String get currentNodeId => _currentNodeId;

  /// Reset context to root
  void resetContext([String? nodeId]) {
    _currentNodeId = nodeId ?? 'root';
    currentBookId = null;
    currentTopicId = null;
    currentCardIndex = null;
    currentVocabList = null;
    currentBooksList = null;
    isCardFlipped = false;
  }

  /// Get available intents for current context
  List<String> getAvailableIntents() {
    return workflowGraph.getAvailableIntents(_currentNodeId);
  }

  /// Main handler - Returns TTS text directly
  /// Handlers emit events internally, no need to return complex maps
  Future<String> handleIntent({
    required String intent,
    Map<String, dynamic>? slots,
  }) async {
    try {
      logger.info('Handling intent: $intent with slots: $slots');

      // System intents always allowed (context management)
      List<String> systemIntents = ['syncFlashCardContext', 'exitFlashCard'];

      // Validate intent against current workflow node (skip for system intents)
      if (!systemIntents.contains(intent)) {
        final availableIntents = getAvailableIntents();
        if (!availableIntents.contains(intent)) {
          logger.warning(
              'Intent $intent not available in current context $_currentNodeId. Available: $availableIntents');
          return 'Sorry, that command is not available right now';
        }
      }

      // Handle specific intents using extension methods
      final ttsText = switch (intent) {
        'listBook' => await handleListBook(),
        'selectBook' =>
          await handleSelectBook(slots?['bookId'] ?? slots?['bookName']),
        'syncFlashCardContext' => await syncFlashCardContext(slots?['bookId']),
        'exitFlashCard' => await exitFlashCardContext(),
        'nextCard' => await handleNextCard(),
        'prevCard' => await handlePrevCard(),
        'flipCard' => await handleFlipCard(),
        'pronounceWord' => await handlePronounceWord(),
        'repeatWord' => await handleRepeatWord(),
        'exampleSentence' => await handleExampleSentence(),
        'translateWord' => await handleTranslateWord(),
        'spellWord' => await handleSpellWord(),
        'bookmarkWord' => await handleBookmarkWord(),
        'reviewBookmarked' => await handleReviewBookmarked(),
        'nextVocab' => await handleNextVocab(),
        'readAloud' => await handleReadAloud(),
        'startConversation' => await handleStartConversation(),
        'stopConversation' => await handleStopConversation(),
        'exit' => await handleExit(),
        'help' => await handleHelp(),
        _ => 'Sorry, I don\'t understand that command',
      };

      // Update workflow state
      if (!systemIntents.contains(intent) &&
          ttsText != null &&
          !ttsText.startsWith('Sorry')) {
        final nextNode = workflowGraph.getNextNode(_currentNodeId, intent);
        if (nextNode != null) {
          _currentNodeId = nextNode.id;
          logger.info('Moved to node: $_currentNodeId');
        }
      }

      return ttsText;
    } catch (e) {
      logger.error('Error handling intent $intent', e);
      return 'Sorry, something went wrong: $e';
    }
  }

  /// Get current state for debugging
  Map<String, dynamic> getCurrentState() {
    return {
      'currentNodeId': _currentNodeId,
      'currentBookId': currentBookId,
      'currentTopicId': currentTopicId,
      'currentCardIndex': currentCardIndex,
      'availableIntents': getAvailableIntents(),
    };
  }
}
