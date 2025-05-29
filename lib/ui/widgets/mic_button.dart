import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chickies_ui/components/icon_button.dart';
import '../../services/voice_controller.dart';
import '../../core/logger.dart';

class MicButton extends StatefulWidget {
  const MicButton({super.key});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  final VoiceController _controller = VoiceController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeVoiceController();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeVoiceController() async {
    try {
      await _controller.initialize();
    } catch (e) {
      logger.error('Failed to initialize voice controller', e);
      if (mounted) {
        _showErrorSnackbar('Failed to initialize voice services. Please check permissions.');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  void _toggleListening() async {
    try {
      if (_isListening) {
        await _controller.stopListening();
        _animationController.reverse();
      } else {
        await _controller.startListening();
        _animationController.forward();
      }
      if (mounted) {
        setState(() => _isListening = !_isListening);
      }
    } catch (e) {
      logger.error('Error toggling listening state', e);
      if (mounted) {
        _showErrorSnackbar('Error with voice recognition. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VoiceState>(
      stream: _controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? VoiceState.uninitialized;
        final bool isEnabled = state != VoiceState.processing && 
                             state != VoiceState.uninitialized;
        
        // Show permission button if needed
        if (state == VoiceState.needsPermission) {
          return ChickiesIconButton(
            onPressed: () => openAppSettings(),
            icon: Icons.mic_off,
            backgroundColor: Colors.red,
            size: 32,
          );
        }
        
        return ScaleTransition(
          scale: _scaleAnimation,
          child: ChickiesIconButton(
            onPressed: isEnabled ? _toggleListening : () {}, // Provide empty function when disabled
            icon: _getIcon(state),
            backgroundColor: isEnabled ? _getBackgroundColor(state) : Colors.grey,
            size: 32,
          ),
        );
      },
    );
  }

  IconData _getIcon(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.hourglass_empty; // Changed to show processing state with an icon
      case VoiceState.speaking:
        return Icons.volume_up;
      case VoiceState.error:
        return Icons.error_outline;
      case VoiceState.needsPermission:
        return Icons.mic_off;
      case VoiceState.uninitialized:
        return Icons.hourglass_empty;
      case VoiceState.idle:
      default:
        return Icons.mic_none;
    }
  }

  Color _getBackgroundColor(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return Colors.red;
      case VoiceState.processing:
        return Colors.orange;
      case VoiceState.speaking:
        return Colors.blue;
      case VoiceState.error:
        return Colors.red.shade900;
      case VoiceState.needsPermission:
        return Colors.grey;
      case VoiceState.uninitialized:
        return Colors.grey.shade400;
      case VoiceState.idle:
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}