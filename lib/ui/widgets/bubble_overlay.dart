import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import '../../core/app_event_bus.dart';
import '../../voice/simulator/intent_simulator.dart';

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
class BubbleOverlayWithDebug extends StatelessWidget {
  final VoidCallback onClose;
  final ValueChanged<Offset> onMove;

  const BubbleOverlayWithDebug({
    super.key,
    required this.onClose,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        children: [
          BubbleOverlay(onClose: onClose, onMove: onMove),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                color: Colors.transparent,
                child: const DebugAccordion(),
              ),
            ),
          ),
        ],
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

class DebugAccordion extends StatefulWidget {
  const DebugAccordion({super.key});

  @override
  State<DebugAccordion> createState() => _DebugAccordionState();
}

class _DebugAccordionState extends State<DebugAccordion> {
  final List<String> _statusLog = [];
  final IntentSimulator _simulator = IntentSimulator();

  @override
  void initState() {
    super.initState();
    eventBus.stream.listen((event) {
      setState(() {
        _statusLog.add('${event.type}: ${event.payload}');
        if (_statusLog.length > 50) _statusLog.removeAt(0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
                MoonAccordion(
          label: const Text('App Status & Debug'),
            children: [
              const Text('Recent Events:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: _statusLog.length,
                  itemBuilder: (context, i) => Text(_statusLog[_statusLog.length - 1 - i]),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Trigger Intent:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => _simulator.emitSelectBook('English Starter'),
                    child: const Text('Select Book'),
                  ),
                  ElevatedButton(
                    onPressed: () => _simulator.emitSelectTopic('Animals'),
                    child: const Text('Select Topic'),
                  ),
                  ElevatedButton(
                    onPressed: () => _simulator.emitNextVocab(),
                    child: const Text('Next Vocab'),
                  ),
                  ElevatedButton(
                    onPressed: () => _simulator.emitReadAloud(),
                    child: const Text('Read Aloud'),
                  ),
                ],
              ),
            ],
        ),
      ],
    );
  }
}