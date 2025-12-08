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
  String _nativeResult = '';
  String _nativeTime = '';
  bool _isLoading = false;

  // Quick pick examples
  final List<String> _examples = [
    "turn on the lights",
    "play some jazz music",
    "what's the weather like?",
    "set an alarm for 7 am",
    "tell me a joke",
    "send an email to mom",
  ];

  Future<void> _classifyText() async {
     if (_textController.text.isEmpty) return;
     
     setState(() {
       _isLoading = true;
       _nativeResult = 'Running...';
       _nativeTime = '';
     });

     try {
       final nativeStopwatch = Stopwatch()..start();
       final nativeIntent = await NativeClassifier.classify(_textController.text);
       nativeStopwatch.stop();
       
       setState(() {
         _nativeResult = nativeIntent ?? 'Unknown';
         _nativeTime = '${nativeStopwatch.elapsedMilliseconds}ms';
         _isLoading = false;
         
         Logger().i("Native Classification: Result=$nativeIntent | Time=$_nativeTime");
       });

     } catch (e) {
       setState(() {
         _nativeResult = 'Error: $e';
         _isLoading = false;
       });
       Logger().e("Classification error", error: e);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intent Classification Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MoonTextArea(
              controller: _textController,
              hintText: 'Enter text to classify...',
              textPadding: const EdgeInsets.all(6),
            ),
            const SizedBox(height: 16),
            const Text("Quick Picks:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examples.map((example) => MoonChip(
                onTap: () {
                   _textController.text = example;
                   _classifyText();
                },
                borderRadius: BorderRadius.circular(20),
                backgroundColor: context.moonColors!.gohan,
                label: Text(example),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: MoonButton(
                    onTap: _classifyText,
                    backgroundColor: context.moonColors!.piccolo,
                    label: const Text('Classify (Native)'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            if (_nativeResult.isNotEmpty) 
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.moonColors!.gohan,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.moonColors!.beerus),
                ),
                child: Column(
                  children: [
                    const Text("Classification Result", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        const Text("Android Native", style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(_nativeResult, style: TextStyle(color: context.moonColors!.trunks, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(_nativeTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
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
