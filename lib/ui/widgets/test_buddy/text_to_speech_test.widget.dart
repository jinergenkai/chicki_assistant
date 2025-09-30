import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/services/tts_service.dart';

class TextToSpeechTestWidget extends StatefulWidget {
  const TextToSpeechTestWidget({super.key});

  @override
  State<TextToSpeechTestWidget> createState() => _TextToSpeechTestWidgetState();
}

class _TextToSpeechTestWidgetState extends State<TextToSpeechTestWidget> {
  final _ttsService = TextToSpeechService();
  final _textController = TextEditingController(
    text: "Hello, I am your virtual assistant. How can I help you today?",
  );
  bool _isSpeaking = false;
  double _speechRate = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeTTSService();
  }

  Future<void> _initializeTTSService() async {
    try {
      await _ttsService.initialize();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể khởi tạo dịch vụ text to speech: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _speak() async {
    if (_textController.text.isEmpty) return;

    try {
      if (_isSpeaking) {
        await _ttsService.stop();
      } else {
        await _ttsService.speak(_textController.text);
      }
      setState(() => _isSpeaking = _ttsService.isSpeaking);
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể phát âm: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _updateSpeechRate(double value) async {
    try {
      await _ttsService.setSpeechRate(value);
      setState(() => _speechRate = value);
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thay đổi tốc độ nói: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

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
                const Text('Tốc độ: '),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    onChanged: _updateSpeechRate,
                    activeColor: context.moonColors!.piccolo,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _speechRate.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: MoonButton(
                onTap: _speak,
                backgroundColor: _isSpeaking 
                  ? context.moonColors!.gohan 
                  : context.moonColors!.piccolo,
                label: Text(_isSpeaking ? 'Dừng' : 'Đọc'),
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