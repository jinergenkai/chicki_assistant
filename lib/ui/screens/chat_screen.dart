import 'package:chicki_buddy/controllers/voice_controller.dart';
import 'package:chicki_buddy/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';
import '../../models/message.dart';
import '../widgets/mic_button.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_state_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  late final VoiceController _voiceController;
  final _scrollController = ScrollController();
  bool _isInitialized = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _voiceController = Get.find<VoiceController>();
      await _voiceController.initialize();
      _setupVoiceListener();

      // Start wake word detection after initialization
      // await _voiceController.startWakeWordDetection();

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
    // Rx: tự động update UI qua Obx, không cần listen thủ công nữa
    ever<String>(_voiceController.recognizedText, (text) {
      if (text.isNotEmpty) {
        _addMessage(Message.user(text));
        // Reset để tránh lặp lại message khi giá trị không đổi
        _voiceController.recognizedText.value = '';
      }
    });
    ever<String>(_voiceController.gptResponse, (response) {
      if (response.isNotEmpty) {
        _addMessage(Message.assistant(response));
        // Reset để tránh lặp lại message khi giá trị không đổi
        _voiceController.gptResponse.value = '';
      }
    });
  }

  void _addMessage(Message message) {
    _chatController.addMessage(message);
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
      // _voiceController.stopWakeWordDetection();
      _voiceController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFeef2f9),
      appBar: AppBar(
        title: Row(
          children: [
            const MoonAvatar(
              backgroundColor: Colors.white,
              content: Icon(Icons.chat_bubble_outline, color: Color(0xFF4F5D73)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Chat',
                  style: MoonTypography.typography.heading.text20.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trò chuyện AI',
                  style: MoonTypography.typography.body.text12.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0.5,
        toolbarHeight: 64,
        centerTitle: false,
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
                : Obx(() {
                    // Scroll to bottom mỗi khi messages thay đổi
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatController.messages.length,
                      itemBuilder: (context, index) {
                        final message = _chatController.messages[index];
                        return MessageBubble(message: message);
                      },
                    );
                  }),
          ),

          // Voice State Indicator
          Obx(() {
            final state = _voiceController.state.value;
            return VoiceStateIndicator(state: state);
          }),

          // Microphone Button
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: const MicButton(),
          ),
        ],
      ),
    );
  }
}
