import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  _ModelTestScreenState createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  final TextEditingController _textController = TextEditingController(text:"play classic song");
  static const _channel = MethodChannel('intent_classifier');
  String _result = '';
  bool _isLoading = false;

  Future<void> _classifyText() async {
    if (_textController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      var intentId = await _channel.invokeMethod(
        'classify',
        {'text': _textController.text},
      );
      Logger().d("Intent ID: $intentId");
      setState(() {
        _result = 'Intent ID: $intentId';
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = 'Error: ${e.message}';
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
              // maxLines: 3,
            ),
            const SizedBox(height: 16),
            MoonButton(
              // loading: _isLoading,
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
