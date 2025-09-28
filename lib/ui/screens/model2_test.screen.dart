import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MobileBertClassifier {
  Interpreter? _interpreter;

  // ✅ CHÍNH XÁC: MobileBERT thường dùng sequence length = 128
  static const int SEQUENCE_LENGTH = 128;
  static const int NUM_LABELS = 7;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobilebert.tflite');
      print('Model loaded successfully');

      // In thông tin input/output shapes để debug
      final inputDetails = _interpreter!.getInputTensors();
      final outputDetails = _interpreter!.getOutputTensors();

      print('=== INPUT SHAPES ===');
      for (int i = 0; i < inputDetails.length; i++) {
        print('Input $i: ${inputDetails[i].shape}');
      }

      print('=== OUTPUT SHAPES ===');
      for (int i = 0; i < outputDetails.length; i++) {
        print('Output $i: ${outputDetails[i].shape}');
      }
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<Map<String, dynamic>> classifyText(String text) async {
    if (_interpreter == null) {
      throw Exception('Model chưa được load');
    }

    try {
      // === 1. TOKENIZE TEXT (cần tokenizer thật) ===
      // ⚠️ ĐÂY LÀ PLACEHOLDER - Thực tế cần BertTokenizer
      var tokenizeResult = _tokenizeText(text);

      // === 2. CHUẨN BỊ INPUTS với đúng shape ===
      // MobileBERT thường cần 3 inputs: [input_ids, attention_mask, token_type_ids]
      // var inputs = <int, List<List<int>>>{
      //   0: [tokenizeResult['input_ids']!],      // Shape: [1, 128]
      //   1: [tokenizeResult['attention_mask']!], // Shape: [1, 128]
      //   2: [tokenizeResult['token_type_ids']!]  // Shape: [1, 128]
      // };
      var inputs = [[]];

      // === 3. CHUẨN BỊ OUTPUT ===
      var output = List<List<double>>.generate(1, (_) => List.filled(NUM_LABELS, 0.0)); // Shape: [1, NUM_LABELS]

      var outputs = <int, Object>{0: output};

      // === 4. CHẠY INFERENCE ===
      _interpreter!.runForMultipleInputs(inputs, outputs);

      // === 5. POST-PROCESS KẾT QUẢ ===
      List<double> logits = output[0];
      var probabilities = _softmax(logits);

      int predictedClass = probabilities.asMap().entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return {'predicted_class': predictedClass, 'probabilities': probabilities, 'confidence': probabilities[predictedClass], 'raw_logits': logits};
    } catch (e) {
      print('Error during inference: $e');
      rethrow;
    }
  }

  // ⚠️ PLACEHOLDER TOKENIZER - Cần thay bằng BertTokenizer thật
  Map<String, List<int>> _tokenizeText(String text) {
    // Tokenizer giả lập - KHÔNG dùng trong production
    final tokens = text.toLowerCase().split(' ');

    var inputIds = List.filled(SEQUENCE_LENGTH, 0); // [PAD] token = 0
    var attentionMask = List.filled(SEQUENCE_LENGTH, 0);
    var tokenTypeIds = List.filled(SEQUENCE_LENGTH, 0);

    // [CLS] token ở đầu
    inputIds[0] = 101; // [CLS] token id
    attentionMask[0] = 1;
    tokenTypeIds[0] = 0;

    // Thêm tokens (giả lập)
    int idx = 1;
    for (int i = 0; i < tokens.length && idx < SEQUENCE_LENGTH - 1; i++) {
      inputIds[idx] = (tokens[i].hashCode.abs() % 30000) + 1000; // Giả lập vocab
      attentionMask[idx] = 1;
      tokenTypeIds[idx] = 0;
      idx++;
    }

    // [SEP] token ở cuối
    if (idx < SEQUENCE_LENGTH) {
      inputIds[idx] = 102; // [SEP] token id
      attentionMask[idx] = 1;
      tokenTypeIds[idx] = 0;
    }

    return {'input_ids': inputIds, 'attention_mask': attentionMask, 'token_type_ids': tokenTypeIds};
  }

  // Softmax function
  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    List<double> expLogits = logits.map((x) => math.exp(x - maxLogit)).toList();
    double sumExp = expLogits.reduce((a, b) => a + b);
    return expLogits.map((x) => x / sumExp).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

// === WIDGET SỬ DỤNG ===
class TextClassificationDemo extends StatefulWidget {
  const TextClassificationDemo({super.key});

  @override
  _TextClassificationDemoState createState() => _TextClassificationDemoState();
}

class _TextClassificationDemoState extends State<TextClassificationDemo> {
  final MobileBertClassifier _classifier = MobileBertClassifier();
  final TextEditingController _textController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    await _classifier.loadModel();
    setState(() => _isLoading = false);
  }

  Future<void> _classifyText() async {
    if (_textController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _classifier.classifyText(_textController.text);
      setState(() {
        _result = '''
Predicted Class: ${result['predicted_class']}
Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%
Probabilities: ${result['probabilities'].map((p) => (p * 100).toStringAsFixed(2)).join(', ')}%
        ''';
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MobileBERT Text Classification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to classify',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _classifyText,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Classify Text'),
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
    _classifier.dispose();
    _textController.dispose();
    super.dispose();
  }
}

// === CÁC BƯỚC QUAN TRỌNG ĐỂ FIX ===

/*
1. ✅ KIỂM TRA MODEL SHAPE:
   - Dùng Netron (https://netron.app) mở file .tflite
   - Xem input shapes: thường [1, 128] cho sequence length
   - Xem số lượng inputs: thường 3 (input_ids, attention_mask, token_type_ids)

2. ✅ SỬ DỤNG TOKENIZER THẬT:
   dependencies:
     bert_tokenizer: ^0.1.2
   
   import 'package:bert_tokenizer/bert_tokenizer.dart';
   
   final tokenizer = BertTokenizer.fromAssets('assets/vocab.txt');
   final tokens = tokenizer.tokenize(text, maxLength: 128);

3. ✅ CHUẨN BỊ ASSETS:
   flutter:
     assets:
       - assets/models/mobilebert.tflite
       - assets/vocab.txt  # Vocab file cho tokenizer

4. ✅ DEBUG SHAPES:
   - In ra input/output shapes của model
   - Đảm bảo data shape khớp với model expectations

5. ✅ XỬ LÝ LỖI:
   - Wrap trong try-catch
   - Kiểm tra null safety
   - Log chi tiết để debug
*/
