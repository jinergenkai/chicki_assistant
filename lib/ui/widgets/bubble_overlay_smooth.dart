import 'dart:async';
import 'dart:math';
import 'package:chicki_buddy/services/intent_bridge_service.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/core/logger.dart';
import '../../core/app_event_bus.dart';
import '../screens/test_screen/workflow_graph.screen.dart';
import '../../voice/graph/workflow_graph.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Floating assistant bubble with inertia & snap
class SmoothBubbleOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {required VoidCallback onClose}) {
    if (_overlayEntry != null) return; // avoid duplicate
    _overlayEntry = OverlayEntry(
      builder: (_) => SmoothBubble(onClose: () {
        hide();
        onClose();
      }),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    logger.info('SmoothBubbleOverlay shown.');
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    logger.info('SmoothBubbleOverlay hidden.');
  }
}

class SmoothBubble extends StatefulWidget {
  final VoidCallback onClose;

  const SmoothBubble({super.key, required this.onClose});

  @override
  State<SmoothBubble> createState() => _SmoothBubbleState();
}

class _SmoothBubbleState extends State<SmoothBubble> with SingleTickerProviderStateMixin {
  late final Widget _chickyWidget;
  late AnimationController _controller;
  late Animation<Offset> _animation;
  Offset _offset = const Offset(100, 100);
  Offset? _dragStart;
  Offset _velocity = Offset.zero;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _chickyWidget = const WorkflowGraphMiniView();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _controller.addListener(() {
      setState(() => _offset = _animation.value);
    });
    logger.info('SmoothBubble initialized.');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
    _dragStart = details.globalPosition - _offset;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = details.globalPosition - (_dragStart ?? Offset.zero);
      _velocity = details.delta * 16; // rough frame-based velocity estimation
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;

    final velocity = details.velocity.pixelsPerSecond;
    const friction = 0.9;
    Offset newOffset = _offset;

    // Momentum / inertia simulation
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      newOffset += velocity / 60.0;
      final vx = velocity.dx * pow(friction, timer.tick);
      final vy = velocity.dy * pow(friction, timer.tick);
      if (vx.abs() < 10 && vy.abs() < 10) timer.cancel();
      setState(() => _offset = newOffset);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapToEdge();
    });
  }

  void _snapToEdge() {
    final sw = _screenSize.width;
    final sh = _screenSize.height;
    const bubbleWidth = 80.0;
    const bubbleHeight = 80.0;

    final targetX = _offset.dx < sw / 2 ? 10.0 : sw - bubbleWidth - 10.0;
    final targetY = _offset.dy.clamp(30.0, sh - bubbleHeight - 30.0);

    _animation = Tween<Offset>(begin: _offset, end: Offset(targetX, targetY)).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: IgnorePointer(
        ignoring: false,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _chickyWidget,
              // Positioned(
              //   top: -20,
              //   right: -20,
              //   child: IconButton(
              //     icon: const Icon(Icons.close, color: Colors.black, size: 16),
              //     onPressed: widget.onClose,
              //     padding: EdgeInsets.zero,
              //     constraints: const BoxConstraints(),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal workflow graph widget for bubble overlay
class WorkflowGraphMiniView extends StatefulWidget {
  const WorkflowGraphMiniView({super.key});

  @override
  State<WorkflowGraphMiniView> createState() => _WorkflowGraphMiniViewState();
}

class _WorkflowGraphMiniViewState extends State<WorkflowGraphMiniView> {
  WorkflowGraph? _graph;
  String _currentNodeId = 'root';
  bool _loading = true;
  late StreamSubscription<AppEvent> _intentStateSub;
  Map<String, dynamic>? _lastIntentState;

  @override
  void initState() {
    super.initState();
    _loadGraph();
    // Listen for intent state events from event bus
    _intentStateSub = eventBus.stream.where((e) => e.type == AppEventType.intentState).listen((event) {
      final result = event.payload as Map<String, dynamic>;
      _lastIntentState = result;
      // Update node based on intent (not currentNodeId)
      if (_graph != null && result['action'] is String) {
        final intent = result['action'] as String;
        final nextNode = _graph!.getNextNode(_currentNodeId, intent);
        if (nextNode != null) {
          setState(() {
            _currentNodeId = nextNode.id;
          });
        } else {
          setState(() {});
        }
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _intentStateSub.cancel();
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
    // Display generic intent state data
    Widget stateWidget = const SizedBox.shrink();
    if (_lastIntentState != null) {
      final action = _lastIntentState!['action']?.toString() ?? '';
      final data = _lastIntentState!['data'];
      if (data is Map && data.isNotEmpty) {
        stateWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action: $action', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ...data.entries.map((entry) {
              if (entry.value is List) {
                // Render list items
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}:', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ...List.from(entry.value).map((item) => Text(
                          item is Map && item.containsKey('title') ? item['title'] : item.toString(),
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                );
              } else {
                return Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 10));
              }
            }),
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
                node?.label ?? _currentNodeId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (node?.description != null && node!.description.isNotEmpty)
                Text(
                  node.description,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              stateWidget,
              Wrap(
                spacing: 2,
                children: [
                  for (final intent in intents)
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
