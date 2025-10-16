import 'package:flutter/material.dart';

class BubbleOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final ValueChanged<Offset> onMove;

  const BubbleOverlay({
    super.key,
    required this.onClose,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable(
      feedback: _bubbleFace(),
      childWhenDragging: Container(),
      onDragEnd: (details) => onMove(details.offset),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _bubbleFace(),
          Positioned(
            top: -20,
            right: -20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 16),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleFace() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MinimalFacePainter(),
        size: const Size(40, 40),
      ),
    );
  }
}

class _MinimalFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final smilePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw left eye (curve)
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.23, size.height * 0.32, 6, 6),
      0.8,
      1.6,
      false,
      eyePaint,
    );
    // Draw right eye (curve)
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.57, size.height * 0.32, 6, 6),
      0.8,
      1.6,
      false,
      eyePaint,
    );
    // Draw smile (curve)
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.55, 12, 8),
      0.2,
      2.7,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}