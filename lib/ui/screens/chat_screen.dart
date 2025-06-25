import 'package:chicki_buddy/controllers/voice_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';
import '../../models/message.dart';
import '../widgets/mic_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <Message>[].obs;
  late final VoiceController _voiceController;
  final _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _voiceController = VoiceController();
      await _voiceController.initialize();
      _setupVoiceListener();
      
      // Start wake word detection after initialization
      await _voiceController.startWakeWordDetection();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Failed to initialize voice controller: $e');
    }
  }

  void _setupVoiceListener() {
    // Listen to voice state changes
    _voiceController.stateStream.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen for recognized text
    _voiceController.onTextRecognized.listen((text) {
      if (text.isNotEmpty) {
        _addMessage(Message.user(text));
      }
    });

    // Listen for GPT responses
    _voiceController.onGptResponse.listen((response) {
      if (response.isNotEmpty) {
        _addMessage(Message.assistant(response));
      }
    });
  }

  void _addMessage(Message message) {
    _messages.add(message);
    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_isInitialized) {
      _voiceController.stopWakeWordDetection();
      _voiceController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeef2f9),
      appBar: AppBar(
        title: MoonChip(
          chipSize: MoonChipSize.md,
          leading: const Icon(Icons.chat_bubble_outline, size: 20),
          label: Text(
            'Voice Chat',
            style: MoonTypography.typography.heading.text20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: !_isInitialized 
              ? const Center(
                  child: MoonCircularLoader(
                    circularLoaderSize: MoonCircularLoaderSize.sm,
                  ),
                )
              : Obx(() => ListView.builder(
                 controller: _scrollController,
                 padding: const EdgeInsets.all(16),
                 itemCount: _messages.length,
                 itemBuilder: (context, index) {
                   final message = _messages[index];
                   return _buildMessageBubble(message);
                 },
               )),
          ),
          
          // Voice State Indicator
          StreamBuilder<VoiceState>(
            stream: _isInitialized ? _voiceController.stateStream : null,
            builder: (context, snapshot) {
              final state = snapshot.data ?? VoiceState.idle;
              return Container(
                padding: const EdgeInsets.all(8),
                child: MoonTag(
                  tagSize: MoonTagSize.sm,
                  label: Text(
                    _getStateText(state),
                    style: MoonTypography.typography.body.text14.copyWith(
                      color: const Color(0xFF7e7dd6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: const Icon(Icons.graphic_eq, size: 18, color: Color(0xFF7e7dd6)),
                ),
              );
            },
          ),

          // Microphone Button
          const Padding(
            padding: EdgeInsets.all(16),
            child: MicButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const MoonAvatar(
              avatarSize: MoonAvatarSize.sm,
              showBadge: false,
              content: Icon(Icons.android, size: 18),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: MoonChip(
              chipSize: MoonChipSize.md,
              backgroundColor: isUser ? const Color(0xFF7e7dd6) : const Color(0xFFeef2f9),
              textColor: isUser ? Colors.white : Colors.black87,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(12),
              label: Text(
                message.content,
                style: MoonTypography.typography.body.text14.copyWith(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const MoonAvatar(
              avatarSize: MoonAvatarSize.sm,
              showBadge: false,
              content: Icon(Icons.person, size: 18),
            ),
        ],
      ),
    );
  }

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
}