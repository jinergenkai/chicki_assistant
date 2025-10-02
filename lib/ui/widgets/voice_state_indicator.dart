import 'package:chicki_buddy/components/chick_design.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';
import '../../controllers/voice_controller.dart';

class VoiceStateIndicator extends StatefulWidget {
  final VoiceState state;
  const VoiceStateIndicator({super.key, required this.state});

  @override
  State<VoiceStateIndicator> createState() => _VoiceStateIndicatorState();
}

class _VoiceStateIndicatorState extends State<VoiceStateIndicator> {
  final VoiceController _controller = Get.find<VoiceController>();

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
        return 'Tap to start listening';
    }
  }

  void _toggleListening() async {
    try {
      if (_controller.state.value == VoiceState.listening) {
        await _controller.stopListening();
      } else {
        await _controller.startContinuousListeningWithChunking();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error with voice recognition. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleListening,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: ChickTag(
          tagSize: ChickTagSize.sm,
          label: Text(
            _getStateText(widget.state),
            style: const TextStyle(
              color: Color(0xFF7e7dd6),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: const Icon(Icons.graphic_eq, size: 18, color: Color(0xFF7e7dd6)),
        ),
      ),
    );
  }
}
