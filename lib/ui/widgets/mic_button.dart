import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../controllers/voice_controller.dart';
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
          return IconButton(
            onPressed: () => openAppSettings(),
            icon: const Icon(Icons.mic_off, color: Colors.red),
            iconSize: 32,
          );
        }
        
        return ScaleTransition(
          scale: _scaleAnimation,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? _getBackgroundColor(state) : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: isEnabled ? _toggleListening : null,
            icon: Icon(
              _getIcon(state),
              color: Colors.white,
              size: 28,
            ),
            label: Text(
              state == VoiceState.listening
                ? 'Đang nghe'
                : state == VoiceState.processing
                  ? 'Đang xử lý'
                  : state == VoiceState.speaking
                    ? 'Đang nói'
                    : 'Nhấn để nói',
              style: const TextStyle(color: Colors.white),
            ),
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