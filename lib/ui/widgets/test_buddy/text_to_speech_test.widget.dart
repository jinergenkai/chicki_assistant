import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/controllers/tts.controller.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';

class TextToSpeechTestWidget extends StatefulWidget {
  const TextToSpeechTestWidget({super.key});

  @override
  State<TextToSpeechTestWidget> createState() => _TextToSpeechTestWidgetState();
}

class _TextToSpeechTestWidgetState extends State<TextToSpeechTestWidget> {
  final _ttsController = Get.find<TTSController>();
  final _config = Get.find<AppConfigController>();
  final _textController = TextEditingController(
    text: "Hello, I am your virtual assistant. How can I help you today?",
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test Text to Speech',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            MoonTextArea(
              controller: _textController,
              hintText: 'Nhập văn bản cần đọc...',
              textPadding: const EdgeInsets.all(6),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('TTS Engine: '),
                Expanded(
                  child: Obx(() => SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'flutter_tts',
                        label: Text('Flutter TTS'),
                      ),
                      ButtonSegment(
                        value: 'sherpa',
                        label: Text('Sherpa'),
                      ),
                    ],
                    selected: {_config.ttsEngine.value},
                    onSelectionChanged: (Set<String> newSelection) {
                      _config.ttsEngine.value = newSelection.first;
                    },
                  )),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Tốc độ: '),
                Expanded(
                  child: Obx(() => Slider(
                    value: _config.speechRate.value,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    onChanged: (value) async {
                      _config.speechRate.value = value;
                      try {
                        await _ttsController.setSpeechRate(value);
                      } catch (e) {
                        Get.snackbar(
                          'Lỗi',
                          'Không thể thay đổi tốc độ nói: $e',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    activeColor: context.moonColors!.piccolo,
                  )),
                ),
                SizedBox(
                  width: 40,
                  child: Obx(() => Text(
                    _config.speechRate.value.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GetBuilder<TTSController>(
                builder: (controller) => MoonButton(
                  onTap: () async {
                    if (_textController.text.isEmpty) return;

                    try {
                      if (controller.isSpeaking) {
                        await controller.stop();
                      } else {
                        await controller.speak(_textController.text);
                      }
                    } catch (e) {
                      Get.snackbar(
                        'Lỗi',
                        'Không thể phát âm: $e',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  backgroundColor: controller.isSpeaking
                    ? context.moonColors!.gohan
                    : context.moonColors!.piccolo,
                  label: Text(controller.isSpeaking ? 'Dừng' : 'Đọc'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}