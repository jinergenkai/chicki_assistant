import 'dart:async';
import 'dart:ui';

import 'package:chicki_buddy/controllers/voice_controller.dart';
import 'package:chicki_buddy/controllers/chat_controller.dart';
import 'package:chicki_buddy/ui/widgets/moon_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../core/app_event_bus.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';
import '../../models/message.dart';
import '../widgets/mic_button.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_state_indicator.dart';

class ChickyScreen extends StatefulWidget {
  const ChickyScreen({super.key});

  @override
  State<ChickyScreen> createState() => _ChickyScreenState();
}

class _ChickyScreenState extends State<ChickyScreen> {
  final VoiceController _voiceController = Get.find<VoiceController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        // Modern dark chill purple gradient background
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/overlay.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            // Minimal UI: big animated text in center, listen to eventBus for
            Center(
              child: Column(
                children: [
                  _AssistantBigText(),
                  MoonIconButton(
                    icon: _voiceController.isForegroundServiceActive ? LucideIcons.stopCircle : LucideIcons.playCircle,
                    onTap: () => {
                      if (_voiceController.isForegroundServiceActive)
                        _voiceController.stopForegroundService()
                      else _voiceController.startForegroundService(),
                      setState(() {}),
                    },
                  )
                ],
              ),
            ),
            // Microphone Button at bottom
            // Voice State Indicator
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child:
                  // Voice State Indicator
                  Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.2),
                child: Obx(() {
                  final state = _voiceController.state.value;
                  return VoiceStateIndicator(state: state);
                }),
              ),
            ),
          ],
        ));
  }
}

// Widget to display big animated assistant text
class _AssistantBigText extends StatefulWidget {
  @override
  State<_AssistantBigText> createState() => _AssistantBigTextState();
}

class _AssistantBigTextState extends State<_AssistantBigText> {
  String _text = 'Say something...';
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = eventBus.stream.listen((event) {
      if (event.type == AppEventType.assistantMessage) {
        if (mounted) {
          setState(() {
            _text = event.payload ?? '';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Split text into up to 3 lines, each line 2-3 words, last line biggest
    final words = _text.split(' ');
    List<String> lines = [];
    int i = 0;
    while (i < words.length) {
      int take = (lines.length == 2) ? words.length - i : (words.length - i > 2 ? 2 : words.length - i);
      lines.add(words.sublist(i, i + take).join(' '));
      i += take;
      if (lines.length == 3) break;
    }
    while (lines.length < 3) lines.add('');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lines[0],
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          lines[1],
          style: const TextStyle(
            fontSize: 36,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          lines[2],
          style: const TextStyle(
            fontSize: 48,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
