import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/voice/graph/workflow_graph.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class WorkflowGraphView extends StatefulWidget {
  const WorkflowGraphView({super.key});

  @override
  State<WorkflowGraphView> createState() => _WorkflowGraphViewState();
}

class _WorkflowGraphViewState extends State<WorkflowGraphView> {
  WorkflowGraph? _graph;
  String _currentNodeId = 'root';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGraph();
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

  void _moveToNext(String intent) {
    if (_graph == null) return;
    final nextNode = _graph!.getNextNode(_currentNodeId, intent);
    if (nextNode != null) {
      setState(() {
        _currentNodeId = nextNode.id;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No transition for intent "$intent" from node "$_currentNodeId"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _graph == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final node = _graph!.nodes[_currentNodeId];
    final intents = node?.allowedIntents ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Workflow Context')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Node: ${node?.label ?? _currentNodeId}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (node?.description != null && node!.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(node.description),
              ),
            const SizedBox(height: 24),
            Text('Available Actions:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                for (final intent in intents)
                  ElevatedButton(
                    onPressed: () => _moveToNext(intent),
                    child: Text(intent),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
