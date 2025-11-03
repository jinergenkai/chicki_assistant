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

enum IntentSource { ui, speech }

/// Unified handler for both UI clicks and speech intents
/// Keeps WorkflowGraph for flexibility but simplifies the handling
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

  /// Main handler for both UI and speech intents
  Future<Map<String, dynamic>> handleIntent({
    required String intent,
    Map<String, dynamic>? slots,
    required IntentSource source,
  }) async {
    try {
      logger.info('Handling intent: $intent from ${source.name} with slots: $slots');

      // System intents always allowed (context management)
      List<String> systemIntents = ['syncFlashCardContext', 'exitFlashCard'];

      // Validate intent against current workflow node (skip for system intents)
      if (!systemIntents.contains(intent)) {
        final availableIntents = getAvailableIntents();
        if (!availableIntents.contains(intent)) {
          logger.warning('Intent $intent not available in current context $_currentNodeId. Available: $availableIntents');
          return createErrorResponse(intent, 'Intent not available in current context', source);
        }
      }

      // Handle specific intents using extension methods
      final response = switch (intent) {
        'listBook' => await handleListBook(source),
        'selectBook' => await handleSelectBook(slots?['bookId'] ?? slots?['bookName'], source),
        'syncFlashCardContext' => await syncFlashCardContext(slots?['bookId'], source),
        'exitFlashCard' => await exitFlashCardContext(source),
        'nextCard' => await handleNextCard(source),
        'prevCard' => await handlePrevCard(source),
        'flipCard' => await handleFlipCard(source),
        'pronounceWord' => await handlePronounceWord(source),
        'repeatWord' => await handleRepeatWord(source),
        'exampleSentence' => await handleExampleSentence(source),
        'translateWord' => await handleTranslateWord(source),
        'spellWord' => await handleSpellWord(source),
        'bookmarkWord' => await handleBookmarkWord(source),
        'reviewBookmarked' => await handleReviewBookmarked(source),
        'nextVocab' => await handleNextVocab(source),
        'readAloud' => await handleReadAloud(source),
        'startConversation' => await handleStartConversation(source),
        'stopConversation' => await handleStopConversation(source),
        'exit' => await handleExit(source),
        'help' => await handleHelp(source),
        _ => createUnknownResponse(intent, slots, source),
      };

      // Nếi là lỗi, unknown, hoặc system intent thì không update nextNode
      systemIntents = ['syncFlashCardContext', 'exitFlashCard'];
      if (response['action'] == 'error' ||
          response['action'] == 'unknown' ||
          systemIntents.contains(intent)) {
        if (response['action'] == 'error' || response['action'] == 'unknown') {
          logger.warning('No node update due to error or unknown intent: $intent');
        }

        // Check for forced node update (for system intents)
        if (response.containsKey('_forceNodeUpdate')) {
          final forcedNodeId = response['_forceNodeUpdate'] as String;
          if (workflowGraph.nodes.containsKey(forcedNodeId)) {
            _currentNodeId = forcedNodeId;
            logger.info('Forced node update to: $_currentNodeId');
          }
          response.remove('_forceNodeUpdate'); // Clean up internal marker
        }

        return response;
      }

      // Update workflow state bình thường
      final nextNode = workflowGraph.getNextNode(_currentNodeId, intent);
      if (nextNode != null) {
        _currentNodeId = nextNode.id;
        logger.info('Moved to node: $_currentNodeId');
      }

      return response;
    } catch (e) {
      logger.error('Error handling intent $intent', e);
      return createErrorResponse(intent, e.toString(), source);
    }
  }

  // Helper methods (public for extensions to use)
  Map<String, dynamic> createErrorResponse(String intent, String error, IntentSource source) {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Sorry, I cannot $intent right now. $error',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'error',
        'data': {'intent': intent, 'error': error},
        'requiresUI': false,
      };
    }
  }

  Map<String, dynamic> createUnknownResponse(String intent, Map<String, dynamic>? slots, IntentSource source) {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'I don\'t understand that command',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'unknown',
        'data': {'intent': intent, 'slots': slots ?? {}},
        'requiresUI': false,
      };
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
