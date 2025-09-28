import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  State<ModelTestScreen> createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  String _result = "Chưa chạy model";

  Future<void> _runModel({String text = 'text'}) async {
    try {
      final interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      
      const int sequenceLength = 512; // match model
      const int numLabels = 60;

      var inputIds = List.filled(sequenceLength, 0);
      var attentionMask = List.filled(sequenceLength, 0);
      var segmentIds = List.filled(sequenceLength, 0);

      final tokens = text.split(" ");
      for (int i = 0; i < tokens.length && i < sequenceLength; i++) {
        inputIds[i] = i + 1;
        attentionMask[i] = 1;
        segmentIds[i] = 0;
      }

      var inputs = [
        [inputIds], // shape [1, sequenceLength]
        [attentionMask], // shape [1, sequenceLength]
        [segmentIds], // shape [1, sequenceLength]
      ];

      var output = List.filled(1 * numLabels, 0.0).reshape([1, numLabels]);
      var outputs = <int, Object>{0: output};

      interpreter.runForMultipleInputs(inputs, outputs); // ✅ đúng API

      setState(() {
        _result = output.toString();
      });
    } catch (e) {
      setState(() {
        _result = "Lỗi: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test TFLite Model")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_result, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runModel,
              child: const Text("Chạy Model"),
            ),
          ],
        ),
      ),
    );
  }
}
