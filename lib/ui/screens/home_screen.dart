import 'package:flutter/material.dart';
import '../../services/voice_controller.dart';
import '../../core/constants.dart';
import '../widgets/mic_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceController _controller = VoiceController();
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVoiceController();
    _setupVoiceStateListener();
  }

  Future<void> _initializeVoiceController() async {
    try {
      await _controller.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize voice services'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupVoiceStateListener() {
    _controller.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _statusMessage = _getStatusMessage(state);
        });
      }
    });
  }

  String _getStatusMessage(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return AppConstants.listeningMessage;
      case VoiceState.processing:
        return AppConstants.processingMessage;
      case VoiceState.error:
        return AppConstants.errorMessage;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _statusMessage,
                key: ValueKey(_statusMessage),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            StreamBuilder<VoiceState>(
              stream: _controller.stateStream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? VoiceState.idle;
                return _buildVisualization(state);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: const MicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildVisualization(VoiceState state) {
    // TODO: Add voice visualization widget here
    return const SizedBox(
      height: 200,
      child: Center(
        child: Text(
          '🎙️',
          style: TextStyle(fontSize: 64),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}