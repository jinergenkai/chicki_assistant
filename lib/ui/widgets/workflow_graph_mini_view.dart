import 'dart:async';
import 'dart:convert';

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/intent_bridge_service.dart';
import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WorkflowGraphMiniView extends StatefulWidget {
  const WorkflowGraphMiniView({super.key});

  @override
  State<WorkflowGraphMiniView> createState() => _WorkflowGraphMiniViewState();
}

class _WorkflowGraphMiniViewState extends State<WorkflowGraphMiniView> {
  WorkflowGraph? _graph;
  String _currentNodeId = 'root';
  bool _loading = true;
  late StreamSubscription<AppEvent> _handlerStateSub;
  Map<String, dynamic>? _handlerState;

  @override
  void initState() {
    super.initState();
    _loadGraph();
    // Listen for handler state events from foreground task
    _handlerStateSub = eventBus.stream.where((e) => e.type == AppEventType.handlerState).listen((event) {
      final state = event.payload as Map<String, dynamic>;
      setState(() {
        _handlerState = state;
        // Sync currentNodeId from handler
        if (state['currentNodeId'] != null) {
          _currentNodeId = state['currentNodeId'] as String;
        }
      });
    });
  }

  @override
  void dispose() {
    _handlerStateSub.cancel();
    super.dispose();
  }

  Future<void> _loadGraph() async {
    final jsonStr = await rootBundle.loadString('assets/data/graph.json');
    final graph = WorkflowGraph.fromJson(jsonDecode(jsonStr));
    setState(() {
      _graph = graph;
      _currentNodeId = graph.nodes.containsKey('root') ? 'root' : graph.nodes.keys.first;
      _loading = false;
    });
  }

  Future<void> _moveToNext(String intent) async {
    IntentBridgeService.triggerUIIntent(
      intent: intent,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _graph == null) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final node = _graph!.nodes[_currentNodeId];
    final intents = node?.allowedIntents ?? [];

    // Get available intents from handler state (more accurate than graph)
    final availableIntents = _handlerState != null && _handlerState!['availableIntents'] is List
        ? List<String>.from(_handlerState!['availableIntents'] as List)
        : intents;

    // Build dynamic context name based on current state
    String contextName = node?.label ?? _currentNodeId;
    if (_handlerState != null) {
      final bookId = _handlerState!['currentBookId'] as String?;
      final cardIndex = _handlerState!['currentCardIndex'] as int?;

      if (bookId != null && cardIndex != null) {
        // In flashcard mode
        contextName = 'FlashCard: $bookId';
      } else if (bookId != null) {
        // In book context
        contextName = 'Book: $bookId';
      } else if (_currentNodeId == 'root') {
        contextName = 'Home';
      }
    }

    // Display handler state data
    Widget stateWidget = const SizedBox.shrink();
    if (_handlerState != null) {
      final entries = <Widget>[];

      final cardIndex = _handlerState!['currentCardIndex'] as int?;
      if (cardIndex != null) {
        entries.add(Text(
          'Card: $cardIndex',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
        ));
      }

      final topicId = _handlerState!['currentTopicId'] as String?;
      if (topicId != null) {
        entries.add(Text(
          'Topic: $topicId',
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ));
      }

      if (entries.isNotEmpty) {
        stateWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('State:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black54)),
            ...entries,
            const SizedBox(height: 4),
          ],
        );
      }
    }
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 150,
        height: 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                contextName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              stateWidget,
              Wrap(
                spacing: 2,
                children: [
                  for (final intent in availableIntents)
                    GestureDetector(
                      onTap: () => _moveToNext(intent),
                      child: Chip(
                        label: Text(intent, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}