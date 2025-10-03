import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/ui/widgets/test_buddy/waveform_test.widget.dart';
import 'package:chicki_buddy/ui/widgets/test_buddy/voice_to_text_test.widget.dart';
import 'package:chicki_buddy/ui/widgets/test_buddy/classify_test.widget.dart';
import 'package:chicki_buddy/ui/widgets/test_buddy/text_to_speech_test.widget.dart';

class TestBuddyScreen extends StatelessWidget {
  const TestBuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Buddy'),
        backgroundColor: context.moonColors!.beerus,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WaveformTestWidget(),
            SizedBox(height: 16),
            VoiceToTextTestWidget(),
            SizedBox(height: 16),
            ClassifyTestWidget(),
            SizedBox(height: 16),
            TextToSpeechTestWidget(),
            SizedBox(height: 200),
          ],
        ),
      ),
    );
  }
}