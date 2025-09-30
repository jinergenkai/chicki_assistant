import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:logger/logger.dart';
import 'package:chicki_buddy/services/native_classifier.service.dart';

class ClassifyTestWidget extends StatefulWidget {
  const ClassifyTestWidget({super.key});

  @override
  State<ClassifyTestWidget> createState() => _ClassifyTestWidgetState();
}

class _ClassifyTestWidgetState extends State<ClassifyTestWidget> {
  final TextEditingController _textController = TextEditingController(text: "play classic song");
  String _result = '';
  bool _isLoading = false;

  Future<void> _classifyText() async {
    if (_textController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final intent = await NativeClassifier.classify(_textController.text);
      Logger().d("Intent: $intent");
      setState(() {
        _result = 'Intent: $intent';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Lỗi: $e';
        _isLoading = false;
      });
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
              'Test Phân loại văn bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            MoonTextArea(
              controller: _textController,
              hintText: 'Nhập văn bản cần phân loại...',
              textPadding: const EdgeInsets.all(6),
            ),
            const SizedBox(height: 16),
            Center(
              child: _isLoading 
                ? const CircularProgressIndicator()
                : MoonButton(
                    onTap: _classifyText,
                    backgroundColor: context.moonColors!.piccolo,
                    label: const Text('Phân loại'),
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _result,
              style: const TextStyle(fontSize: 16),
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