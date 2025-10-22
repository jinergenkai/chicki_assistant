/// Defines the intent graph for state transitions and actions.
/// This is a Dart-based graph for type safety and easy extension.
/// You can later load from JSON if needed.
library;

class IntentGraphNode {
  final String name;
  final String description;
  final List<IntentGraphTransition> transitions;

  IntentGraphNode({
    required this.name,
    required this.description,
    required this.transitions,
  });
}

class IntentGraphTransition {
  final String intent;
  final String? condition; // Optional: Dart expression as string
  final String target;
  final List<String> actions;

  IntentGraphTransition({
    required this.intent,
    this.condition,
    required this.target,
    required this.actions,
  });
}

class IntentGraph {
  final Map<String, IntentGraphNode> nodes;

  IntentGraph({required this.nodes});

  /// Find a transition for the current node and intent
  IntentGraphTransition? findTransition(String nodeName, String intent) {
    final node = nodes[nodeName];
    if (node == null) return null;
    return node.transitions.firstWhere(
      (t) => t.intent == intent,
      // orElse: () => null,
    );
  }
}

/// Example graph definition
final defaultIntentGraph = IntentGraph(nodes: {
  'idle': IntentGraphNode(
    name: 'idle',
    description: 'Initial state, no book selected',
    transitions: [
      IntentGraphTransition(
        intent: 'selectBook',
        condition: 'slots["bookName"] != null',
        target: 'bookSelected',
        actions: ['findBook', 'updateBookContext', 'emitNavigateToBook'],
      ),
    ],
  ),
  'bookSelected': IntentGraphNode(
    name: 'bookSelected',
    description: 'Book is selected, can navigate topics',
    transitions: [
      IntentGraphTransition(
        intent: 'selectTopic',
        condition: 'slots["topicName"] != null',
        target: 'topicSelected',
        actions: ['findTopic', 'updateTopicContext', 'emitNavigateToTopic'],
      ),
      IntentGraphTransition(
        intent: 'listTopics',
        target: 'bookSelected',
        actions: ['emitShowTopicList'],
      ),
    ],
  ),
  'topicSelected': IntentGraphNode(
    name: 'topicSelected',
    description: 'Topic selected, can navigate cards',
    transitions: [
      IntentGraphTransition(
        intent: 'nextVocab',
        target: 'vocabCard',
        actions: ['incrementCardIndex', 'emitShowCard'],
      ),
      IntentGraphTransition(
        intent: 'previousVocab',
        target: 'vocabCard',
        actions: ['decrementCardIndex', 'emitShowCard'],
      ),
      IntentGraphTransition(
        intent: 'readAloud',
        target: 'topicSelected',
        actions: ['speakCurrentCard'],
      ),
    ],
  ),
  'vocabCard': IntentGraphNode(
    name: 'vocabCard',
    description: 'Viewing a vocabulary card',
    transitions: [
      IntentGraphTransition(
        intent: 'nextVocab',
        target: 'vocabCard',
        actions: ['incrementCardIndex', 'emitShowCard'],
      ),
      IntentGraphTransition(
        intent: 'previousVocab',
        target: 'vocabCard',
        actions: ['decrementCardIndex', 'emitShowCard'],
      ),
      IntentGraphTransition(
        intent: 'readAloud',
        target: 'vocabCard',
        actions: ['speakCurrentCard'],
      ),
      IntentGraphTransition(
        intent: 'backToTopic',
        target: 'topicSelected',
        actions: ['emitNavigateToTopic'],
      ),
    ],
  ),
});