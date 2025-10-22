import 'package:flutter_test/flutter_test.dart';
import 'package:chicki_buddy/services/unified_intent_handler.dart';
import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:chicki_buddy/voice/graph/intent_node.dart';
import 'package:chicki_buddy/voice/graph/intent_edge.dart';

class FakeBook {
  final String name;
  FakeBook(this.name);
  Map<String, dynamic> toJson() => {'name': name};
}

class FakeBookService {
  Future<void> init() async {}
  Future<List<FakeBook>> loadAllBooks() async =>
      [FakeBook('Book A'), FakeBook('Book B')];
}

void main() {
  group('UnifiedIntentHandler Tests', () {
    late UnifiedIntentHandler handler;
    late WorkflowGraph graph;

    setUp(() {
      // Create a simple test graph
      final nodes = {
        'root': IntentNode(
          id: 'root',
          label: 'Root',
          description: 'Starting point',
          allowedIntents: ['listBook', 'help'],
        ),
        'book_context': IntentNode(
          id: 'book_context',
          label: 'Book Context',
          description: 'Book selected',
          allowedIntents: ['selectBook', 'listTopic', 'exitBook'],
        ),
      };

      final edges = [
        IntentEdge(from: 'root', intent: 'listBook', to: 'book_context'),
        IntentEdge(from: 'book_context', intent: 'exitBook', to: 'root'),
      ];

      graph = WorkflowGraph(nodes: nodes, edges: edges);
      handler = UnifiedIntentHandler(
        workflowGraph: graph,
        bookService: FakeBookService() as dynamic, // ignore type for test
      );
    });

    test('should handle listBook intent from UI source', () async {
      final result = await handler.handleIntent(
        intent: 'listBook',
        source: IntentSource.ui,
      );

      expect(result['action'], equals('listBook'));
      expect(result['requiresUI'], equals(true));
      expect(result['data'], isNotNull);
      expect(result['data']['books'], isList);
    });

    test('should handle listBook intent from speech source', () async {
      final result = await handler.handleIntent(
        intent: 'listBook',
        source: IntentSource.speech,
      );

      expect(result['action'], equals('speak'));
      expect(result['requiresUI'], equals(false));
      expect(result['text'], contains('books available'));
    });

    test('should handle selectBook intent with slots', () async {
      // First move to book context
      await handler.handleIntent(
        intent: 'listBook',
        source: IntentSource.ui,
      );

      final result = await handler.handleIntent(
        intent: 'selectBook',
        slots: {'bookName': 'Test Book'},
        source: IntentSource.ui,
      );

      expect(result['action'], equals('navigateToBook'));
      expect(result['data']['bookName'], equals('Test Book'));
      expect(handler.currentBookId, isNotNull);
    });

    test('should reject invalid intent for current context', () async {
      // Try to select book without being in book context
      final result = await handler.handleIntent(
        intent: 'selectBook',
        source: IntentSource.ui,
      );

      expect(result['action'], equals('error'));
      expect(result['data']['error'], contains('not available in current context'));
    });

    test('should track workflow state correctly', () async {
      expect(handler.currentNodeId, equals('root'));
      expect(handler.getAvailableIntents(), contains('listBook'));
      expect(handler.getAvailableIntents(), contains('help'));

      // Move to book context
      await handler.handleIntent(
        intent: 'listBook',
        source: IntentSource.ui,
      );

      expect(handler.currentNodeId, equals('book_context'));
      expect(handler.getAvailableIntents(), contains('selectBook'));
      expect(handler.getAvailableIntents(), contains('exitBook'));
    });

    test('should reset context correctly', () async {
      // Move to book context and set some state
      await handler.handleIntent(
        intent: 'listBook',
        source: IntentSource.ui,
      );
      
      handler.currentBookId = 'test_book';
      expect(handler.currentNodeId, equals('book_context'));
      expect(handler.currentBookId, equals('test_book'));

      // Reset context
      handler.resetContext();
      
      expect(handler.currentNodeId, equals('root'));
      expect(handler.currentBookId, isNull);
    });

    test('should handle help intent differently for UI vs speech', () async {
      final uiResult = await handler.handleIntent(
        intent: 'help',
        source: IntentSource.ui,
      );

      final speechResult = await handler.handleIntent(
        intent: 'help',
        source: IntentSource.speech,
      );

      expect(uiResult['action'], equals('help'));
      expect(uiResult['requiresUI'], equals(true));
      expect(uiResult['data']['availableIntents'], isList);

      expect(speechResult['action'], equals('speak'));
      expect(speechResult['requiresUI'], equals(false));
      expect(speechResult['text'], contains('Available commands'));
    });

    test('should handle unknown intent gracefully', () async {
      final result = await handler.handleIntent(
        intent: 'unknownIntent',
        source: IntentSource.speech,
      );

      expect(result['action'], equals('speak'));
      expect(result['text'], contains('don\'t understand'));
    });

    test('should provide current state for debugging', () {
      final state = handler.getCurrentState();
      
      expect(state['currentNodeId'], equals('root'));
      expect(state['availableIntents'], isList);
      expect(state['currentBookId'], isNull);
    });
  });
}