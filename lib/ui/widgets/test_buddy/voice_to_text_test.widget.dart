import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/services/stt_service.dart';
import 'package:chicki_buddy/ui/widgets/waveform_mic_visualizer.dart';

class VoiceToTextTestWidget extends StatefulWidget {
  const VoiceToTextTestWidget({super.key});

  @override
  State<VoiceToTextTestWidget> createState() => _VoiceToTextTestWidgetState();
}

class _VoiceToTextTestWidgetState extends State<VoiceToTextTestWidget> {
  final _sttService = SpeechToTextService();
  final _textController = TextEditingController();
  bool _isListening = false;
  StreamSubscription? _textSubscription;
  StreamSubscription? _rmsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();
  }

  Future<void> _initializeSpeechService() async {
    try {
      await _sttService.initialize();
    } catch (e) {
      // Handle initialization error
      Get.snackbar(
        'Lỗi',
        'Không thể khởi tạo dịch vụ nhận diện giọng nói: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startListening() async {
    try {
      await _sttService.startListening();
      _textSubscription = _sttService.onTextRecognized.listen((text) {
        _textController.text = text;
      });

      setState(() => _isListening = true);
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể bắt đầu nhận diện giọng nói: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopListening() async {
    try {
      await _sttService.stopListening();
      _textSubscription?.cancel();
      _rmsSubscription?.cancel();
      setState(() => _isListening = false);
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể dừng nhận diện giọng nói: $e',
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
              'Test Voice to Text',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 100,
                child: WaveformMicVisualizer(
                  rmsStream: _sttService.onRmsChanged,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            MoonTextArea(
              controller: _textController,
              hintText: 'Văn bản nhận dạng được...',
              textPadding: const EdgeInsets.all(6),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Center(
              child: MoonButton(
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                backgroundColor: _isListening 
                  ? context.moonColors!.gohan 
                  : context.moonColors!.piccolo,
                label: Text(_isListening ? 'Dừng' : 'Bắt đầu ghi âm'),
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
    _textSubscription?.cancel();
    _rmsSubscription?.cancel();
    super.dispose();
  }
}