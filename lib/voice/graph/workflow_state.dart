import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkflowState {
  final WorkflowGraph graph;
  String currentNodeId;

  WorkflowState({required this.graph, this.currentNodeId = 'root'});

  Future<void> moveNext(String intent) async {
    final nextNode = graph.getNextNode(currentNodeId, intent);
    if (nextNode == null) {
      print("Invalid transition from $currentNodeId with intent $intent");
      return;
    }
    currentNodeId = nextNode.id;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentNodeId', currentNodeId);
  }

  static Future<WorkflowState> load(WorkflowGraph graph) async {
    final prefs = await SharedPreferences.getInstance();
    final node = prefs.getString('currentNodeId') ?? 'root';
    return WorkflowState(graph: graph, currentNodeId: node);
  }
}
