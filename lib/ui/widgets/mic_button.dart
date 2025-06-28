import 'dart:async';
import 'package:get/get.dart';
import 'package:chicki_buddy/ui/widgets/waveform_mic_visualizer.dart';
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
  final VoiceController _controller = Get.find<VoiceController>();
  bool _isListening = false;
  bool _dialogShowing = false;
  late Worker _stateWorker;

  @override
  void initState() {
    super.initState();
    _initializeVoiceController();
    _stateWorker = ever<VoiceState>(_controller.state, (state) {
      logger.info('MicButton: VoiceState changed: $state');
      if (_dialogShowing && state != VoiceState.listening) {
        logger.info('MicButton: Closing dialog because state=$state');
        if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
        _dialogShowing = false;
      }
    });
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
        logger.info('MicButton: Stopping listening');
        await _controller.stopListening();
        if (_dialogShowing && mounted) {
          logger.info('MicButton: Closing dialog from toggle');
          Navigator.of(context, rootNavigator: true).maybePop();
          _dialogShowing = false;
        }
      } else {
        logger.info('MicButton: Starting listening');
        await _controller.startListening();
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
    return Obx(() {
      final state = _controller.state.value;
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

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
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
          // Hiển thị waveform bên dưới mic
          if (state == VoiceState.listening)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WaveformMicVisualizer(
                rmsStream: _controller.rmsDB.stream,
                color: Theme.of(context).colorScheme.primary,
                height: 40,
              ),
            ),
        ],
      );
    });
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
    _stateWorker.dispose();
    super.dispose();
  }
}

class _MicVoiceDialog extends StatelessWidget {
  final VoiceController controller;
  const _MicVoiceDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Obx(() {
          final state = controller.state.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == VoiceState.listening)
                WaveformMicVisualizer(
                  rmsStream: controller.rmsDB.stream,
                  color: theme.colorScheme.primary,
                  height: 72,
                ),
              const SizedBox(height: 24),
              Text(
                "Đang lắng nghe...",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}