import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/core/logger.dart';
import '../../voice/simulator/intent_simulator.dart';
import '../../core/app_event_bus.dart';
import 'chicky/chicky_rive.dart';

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

class _SmoothBubbleState extends State<SmoothBubble>
    with SingleTickerProviderStateMixin {
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
    _chickyWidget = const ChickyRive(state: ChickyState.sleep, size: 80);
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

    _animation = Tween<Offset>(begin: _offset, end: Offset(targetX, targetY))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
