// Dart

import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:chicki_buddy/voice/graph/intent_node.dart';
import 'package:chicki_buddy/voice/graph/intent_edge.dart';
import 'package:chicki_buddy/voice/dispatcher/voice_intent_dispatcher.dart';
import 'package:chicki_buddy/voice/models/voice_intent_payload.dart';
import 'package:chicki_buddy/voice/models/voice_action_event.dart';

/// Service quản lý intent và context hệ thống, dùng WorkflowGraph để track context.
/// CRUD context, trigger intent (ví dụ: book/vocab), chọn action phù hợp và emit event.
/// Không dùng isolate, emit event trực tiếp.
class IntentSystemService {
  final WorkflowGraph workflowGraph;
  final VoiceIntentDispatcher dispatcher;

  /// Node hiện tại trong workflow (id)
  String _currentNodeId;

  IntentSystemService({
    required this.workflowGraph,
    required this.dispatcher,
    String? initialNodeId,
  }) : _currentNodeId = initialNodeId ?? 'root';

  /// Lấy node hiện tại
  IntentNode? get currentNode => workflowGraph.nodes[_currentNodeId];

  /// Lấy id node hiện tại
  String get currentNodeId => _currentNodeId;

  /// Đặt lại context về node gốc
  void resetContext([String? nodeId]) {
    _currentNodeId = nodeId ?? 'root';
  }

  /// Lấy các intent khả dụng ở node hiện tại
  List<String> getAvailableIntents() {
    return workflowGraph.getAvailableIntents(_currentNodeId);
  }

  /// Thực hiện intent, cập nhật context, trả về event
  Future<VoiceActionEvent> triggerIntent(String intent, {Map<String, dynamic>? slots}) async {
    // Chuyển node nếu intent hợp lệ
    final nextNode = workflowGraph.getNextNode(_currentNodeId, intent);
    if (nextNode != null) {
      _currentNodeId = nextNode.id;
    }
    // Tạo payload và dispatch
    final payload = VoiceIntentPayload(
      intent: intent,
      slots: slots ?? {},
    );
    final event = await dispatcher.dispatch(payload);
    // Có thể emit event tại đây nếu cần (ví dụ: qua event bus)
    return event;
  }
}