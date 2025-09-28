import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  State<ModelTestScreen> createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  String _result = "Chưa chạy model";
  Map<String, int> _vocab = {};
  final int _unkToken = 100;

  @override
  void initState() {
    super.initState();
    _loadVocab();
  }

  Future<void> _loadVocab() async {
    try {
      final String vocabContent = await DefaultAssetBundle.of(context).loadString('assets/models/vocab.txt');

      final List<String> lines = vocabContent.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final String token = lines[i].trim();
        if (token.isNotEmpty) {
          _vocab[token] = i;
        }
      }
    } catch (e) {
      print('Error loading vocab: $e');
      // Initialize with basic tokens if vocab file not found
      _vocab = {
        '[PAD]': 0,
        '[UNK]': 100,
        '[CLS]': 101,
        '[SEP]': 102,
      };
    }
  }

  List<int> _tokenize(String text) {
    final tokens = text.toLowerCase().split(' ');
    final List<int> ids = [_vocab['[CLS]'] ?? 101]; // Start with CLS token

    for (final token in tokens) {
      if (_vocab.containsKey(token)) {
        ids.add(_vocab[token]!);
      } else {
        ids.add(_unkToken); // Unknown token
      }
    }

    ids.add(_vocab['[SEP]'] ?? 102); // End with SEP token
    return ids;
  }

  Future<void> _runModel({String text = 'set alarm'}) async {
    try {
      // Đảm bảo vocab đã được load
      print('Vocab size: ${_vocab.length}');
      if (_vocab.isEmpty) {
        await _loadVocab();
      }

      final interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      interpreter.allocateTensors();
      _debugModelShape();

      const int sequenceLength = 512; // match model
      const int numLabels = 60;

      var inputIds = List.filled(sequenceLength, 0, growable: false);
      var attentionMask = List.filled(sequenceLength, 0, growable: false);

      final tokenIds = _tokenize(text);

      // Fill input arrays
      for (int i = 0; i < sequenceLength; i++) {
        if (i < tokenIds.length) {
          inputIds[i] = tokenIds[i];
          attentionMask[i] = 1;
        } else {
          // Padding
          inputIds[i] = _vocab['[PAD]'] ?? 0;
          attentionMask[i] = 0;
        }
      }

      // Debug tokenization
      print('Input text: $text');
      print('Token IDs: ${tokenIds.take(10)}...');
      print('Attention mask: ${attentionMask.take(10)}...');

      var input1 = Int64List.fromList(inputIds).reshape([1, 512]);
      var input2 = Int64List.fromList(attentionMask).reshape([1, 512]);

      // CRITICAL FIX: Allocate output as 2D array [1, 60]
      var output = List.generate(1, (_) => List.filled(numLabels, 0.0));
      interpreter.allocateTensors();
      interpreter.runForMultipleInputs([input1, input2], {0: output});
      print("first output after run: ${output[0].take(10)}");

      // Extract results from 2D array
      List<double> logits = List<double>.from(output[0]);

      // Debug raw logits
      print('Raw logits: ${logits.take(10)}');
      print('All logits sum: ${logits.reduce((a, b) => a + b)}');
      print('Max logit: ${logits.reduce((a, b) => a > b ? a : b)}');
      print('Min logit: ${logits.reduce((a, b) => a < b ? a : b)}');

      List<double> probs = _softmax(logits);
      int predClass = _argmax(probs);
      double confidence = probs[predClass];

      // Debug predictions
      print('Top 5 predictions:');
      var indexedProbs = probs.asMap().entries.toList();
      indexedProbs.sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < 5; i++) {
        print('Class ${indexedProbs[i].key}: ${indexedProbs[i].value.toStringAsFixed(4)}');
      }

      setState(() {
        _result = {'class': predClass, 'confidence': confidence.toStringAsFixed(4), 'top3': indexedProbs.take(3).map((e) => '${e.key}:${e.value.toStringAsFixed(3)}').join(', ')}.toString();
        print('class: $predClass, confidence: ${confidence.toStringAsFixed(4)}');
      });
    } catch (e) {
      setState(() {
        _result = "Lỗi: $e";
      });
    }
  }

  void _debugModelShape() async {
    final interpreter = await Interpreter.fromAsset('assets/models/model.tflite');

    // Check input tensors
    for (int i = 0; i < interpreter.getInputTensors().length; i++) {
      var tensor = interpreter.getInputTensor(i);
      print('Input $i: ${tensor.shape}, type: ${tensor.type}');
    }

    // Check output tensors
    for (int i = 0; i < interpreter.getOutputTensors().length; i++) {
      var tensor = interpreter.getOutputTensor(i);
      print('Output $i: ${tensor.shape}, type: ${tensor.type}');
    }
  }

  Future<void> _validateModel() async {
    try {
      final interpreter = await Interpreter.fromAsset('assets/models/model.tflite');

      // Test với input cực đơn giản
      var simpleInput1 = Int64List(512);
      var simpleInput2 = Int64List(512);
      simpleInput1[0] = 1; // Chỉ có 1 số khác 0
      simpleInput2[0] = 1;

      var output = List.generate(1, (_) => List.filled(60, 0.0));
      interpreter.runForMultipleInputs([
        simpleInput1.reshape([1, 512]),
        simpleInput2.reshape([1, 512])
      ], {
        0: output
      });

      var result1 = _argmax(_softmax(List<double>.from(output[0])));

      // Test với input khác
      simpleInput1[0] = 100;
      simpleInput1[1] = 200;
      interpreter.runForMultipleInputs([
        simpleInput1.reshape([1, 512]),
        simpleInput2.reshape([1, 512])
      ], {
        0: output
      });

      var result2 = _argmax(_softmax(List<double>.from(output[0])));

      print("Simple test 1 -> $result1");
      print("Simple test 2 -> $result2");

      if (result1 == result2) {
        print("⚠️  WARNING: Model producing same output for different inputs!");
      }
    } catch (e) {
      print("Model validation error: $e");
    }
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];

    final maxLogit = logits.reduce(math.max);
    final exp = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sumExp = exp.reduce((a, b) => a + b);

    return sumExp > 0 ? exp.map((x) => x / sumExp).toList() : List.filled(logits.length, 1.0 / logits.length);
  }

  int _argmax(List<double> list) {
    if (list.isEmpty) return -1;

    int maxIdx = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > list[maxIdx]) maxIdx = i;
    }

    return maxIdx;
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: "play classic songs");

    return Scaffold(
      appBar: AppBar(title: const Text("Test TFLite Model")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Text để phân loại',
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: set alarm, play music...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _runModel(text: textController.text);
                  // _validateModel();
                }
              },
              child: const Text("Phân loại"),
            ),
            const SizedBox(height: 20),
            Text(
              _result,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// extension ExpDouble on double {
//   double exp() => (this == 0) ? 1.0 : double.parse((math.exp(this)).toString());
// }
