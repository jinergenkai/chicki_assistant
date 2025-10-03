import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/services/native_classifier.service.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  _ModelTestScreenState createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  final TextEditingController _textController = TextEditingController(text:"play classic song");
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
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intent Classification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MoonTextArea(
              controller: _textController,
              hintText: 'Enter text to classify...',
              textPadding: const EdgeInsets.all(6),
            ),
            const SizedBox(height: 16),
            MoonButton(
              onTap: _classifyText,
              backgroundColor: context.moonColors!.piccolo,
              label: const Text('Classify'),
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
