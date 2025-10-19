import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/ui/widgets/bubble_overlay.dart';
import 'package:chicki_buddy/voice/simulator/intent_simulator.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
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
          // BubbleOverlay(onClose: onClose, onMove: onMove),
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