import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/core/logger.dart';
import '../../core/app_event_bus.dart';
import '../../voice/simulator/intent_simulator.dart';
import 'chicky/chicky_rive.dart';

class BubbleOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<Offset> onMove;

  const BubbleOverlay({
    super.key,
    required this.onClose,
    required this.onMove,
  });

  @override
  State<BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<BubbleOverlay> {
  late final Widget _chickyWidget;

  Offset _offset = const Offset(100, 100); // initial position
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _chickyWidget = const ChickyRive(state: ChickyState.sleep, size: 80);
    logger.info('Smooth BubbleOverlay initialized (gesture-based).');
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.globalPosition - _offset;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = details.globalPosition - (_dragStart ?? Offset.zero);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;
    widget.onMove(_offset); // report new position
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: _chickyWidget,
      ),
    );
  }
}
