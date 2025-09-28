import 'package:chicki_buddy/components/chick_design.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import '../../controllers/voice_controller.dart';

class VoiceStateIndicator extends StatelessWidget {
  final VoiceState state;
  const VoiceStateIndicator({super.key, required this.state});

  String _getStateText(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.processing:
        return 'Processing...';
      case VoiceState.speaking:
        return 'Speaking...';
      case VoiceState.detecting:
        return 'Wake word detected!';
      case VoiceState.error:
        return 'Error occurred';
      case VoiceState.needsPermission:
        return 'Microphone permission needed';
      case VoiceState.uninitialized:
        return 'Initializing...';
      case VoiceState.idle:
        return 'Say "Hey Chicki" to start';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ChickTag(
        tagSize: ChickTagSize.sm,
        label: Text(
          _getStateText(state),
          style: const TextStyle(
            color: Color(0xFF7e7dd6),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const Icon(Icons.graphic_eq, size: 18, color: Color(0xFF7e7dd6)),
      ),
    );
  }
}