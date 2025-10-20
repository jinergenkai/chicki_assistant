
import 'package:chicki_buddy/voice/graph/intent_edge.dart';
import 'package:chicki_buddy/voice/graph/intent_node.dart';

class WorkflowGraph {
  final Map<String, IntentNode> nodes;
  final List<IntentEdge> edges;

  WorkflowGraph({required this.nodes, required this.edges});

  factory WorkflowGraph.fromJson(Map<String, dynamic> json) {
    final nodeMap = {
      for (var n in json['nodes']) n['id'] as String: IntentNode.fromJson(n)
    };
    final edgeList =
        (json['edges'] as List).map((e) => IntentEdge.fromJson(e)).toList();

    return WorkflowGraph(nodes: nodeMap, edges: edgeList);
  }

  /// Get next node if valid transition
  IntentNode? getNextNode(String currentNodeId, String intent) {
    final edge =
        edges.firstWhere((e) => e.from == currentNodeId && e.intent == intent,
            orElse: () => IntentEdge(from: '', intent: '', to: ''));
    return nodes[edge.to];
  }

  List<String> getAvailableIntents(String nodeId) {
    return nodes[nodeId]?.allowedIntents ?? [];
  }
}