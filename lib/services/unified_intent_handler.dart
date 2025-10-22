import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:chicki_buddy/voice/graph/intent_node.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/core/logger.dart';

enum IntentSource { ui, speech }

/// Unified handler for both UI clicks and speech intents
/// Keeps WorkflowGraph for flexibility but simplifies the handling
class UnifiedIntentHandler {
  final WorkflowGraph workflowGraph;
  final BookService bookService;
  
  /// Current node in workflow (context tracking)
  String _currentNodeId;
  
  /// Current state for context
  String? currentBookId;
  String? currentTopicId;
  int? currentCardIndex;

  UnifiedIntentHandler({
    required this.workflowGraph,
    BookService? bookService,
    String? initialNodeId,
  })  : bookService = bookService ?? BookService(),
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
      
      // Validate intent against current workflow node
      final availableIntents = getAvailableIntents();
      if (!availableIntents.contains(intent)) {
        logger.warning('Intent $intent not available in current context $_currentNodeId. Available: $availableIntents');
        return _createErrorResponse(intent, 'Intent not available in current context', source);
      }

      // Update workflow state
      final nextNode = workflowGraph.getNextNode(_currentNodeId, intent);
      if (nextNode != null) {
        _currentNodeId = nextNode.id;
        logger.info('Moved to node: $_currentNodeId');
      }

      // Handle specific intents
      switch (intent) {
        case 'listBook':
          return await _handleListBook(source);
          
        case 'selectBook':
          return await _handleSelectBook(slots?['bookName'], source);
          
        case 'listTopic':
          return await _handleListTopic(source);
          
        case 'selectTopic':
          return await _handleSelectTopic(slots?['topicName'], source);
          
        case 'nextVocab':
          return await _handleNextVocab(source);
          
        case 'readAloud':
          return await _handleReadAloud(source);
          
        case 'start_conversation':
          return await _handleStartConversation(source);
          
        case 'stop_conversation':
          return await _handleStopConversation(source);
          
        case 'exitBook':
          return await _handleExitBook(source);
          
        case 'help':
          return await _handleHelp(source);
          
        default:
          return _createUnknownResponse(intent, slots, source);
      }
    } catch (e) {
      logger.error('Error handling intent $intent', e);
      return _createErrorResponse(intent, e.toString(), source);
    }
  }

  // Intent handlers
  Future<Map<String, dynamic>> _handleListBook(IntentSource source) async {
    await bookService.init();
    final books = await bookService.loadAllBooks();
    
    if (source == IntentSource.speech) {
      // Speech: Simple TTS response
      return {
        'action': 'speak',
        'text': 'I found ${books.length} books available',
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

  Future<Map<String, dynamic>> _handleSelectBook(String? bookName, IntentSource source) async {
    if (bookName == null) {
      return _createErrorResponse('selectBook', 'Book name is required', source);
    }
    
    // Simulate book lookup (replace with actual lookup)
    currentBookId = 'book_${bookName.toLowerCase().replaceAll(' ', '_')}';
    
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Opening $bookName',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'navigateToBook',
        'data': {'bookId': currentBookId, 'bookName': bookName},
        'requiresUI': true,
      };
    }
  }

  Future<Map<String, dynamic>> _handleListTopic(IntentSource source) async {
    if (currentBookId == null) {
      return _createErrorResponse('listTopic', 'No book selected', source);
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

  Future<Map<String, dynamic>> _handleSelectTopic(String? topicName, IntentSource source) async {
    if (topicName == null) {
      return _createErrorResponse('selectTopic', 'Topic name is required', source);
    }
    
    currentTopicId = 'topic_${topicName.toLowerCase()}';
    
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Selected topic: $topicName',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'navigateToTopic',
        'data': {'topicId': currentTopicId, 'topicName': topicName},
        'requiresUI': true,
      };
    }
  }

  Future<Map<String, dynamic>> _handleNextVocab(IntentSource source) async {
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

  Future<Map<String, dynamic>> _handleReadAloud(IntentSource source) async {
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

  Future<Map<String, dynamic>> _handleStartConversation(IntentSource source) async {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Starting conversation mode. How can I help you?',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'startConversation',
        'data': {},
        'requiresUI': true,
      };
    }
  }

  Future<Map<String, dynamic>> _handleStopConversation(IntentSource source) async {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Conversation ended',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'stopConversation',
        'data': {},
        'requiresUI': true,
      };
    }
  }

  Future<Map<String, dynamic>> _handleExitBook(IntentSource source) async {
    currentBookId = null;
    currentTopicId = null;
    currentCardIndex = null;
    
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Exited book',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'exitBook',
        'data': {},
        'requiresUI': true,
      };
    }
  }

  Future<Map<String, dynamic>> _handleHelp(IntentSource source) async {
    final availableIntents = getAvailableIntents();
    
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'Available commands: ${availableIntents.join(', ')}',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'help',
        'data': {'availableIntents': availableIntents},
        'requiresUI': true,
      };
    }
  }

  // Helper methods
  Map<String, dynamic> _createErrorResponse(String intent, String error, IntentSource source) {
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

  Map<String, dynamic> _createUnknownResponse(String intent, Map<String, dynamic>? slots, IntentSource source) {
    if (source == IntentSource.speech) {
      return {
        'action': 'speak',
        'text': 'I don\'t understand that command',
        'requiresUI': false,
      };
    } else {
      return {
        'action': 'unknownIntent',
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