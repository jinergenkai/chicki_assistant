// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:logger/logger.dart';
// import 'dart:convert';
// import 'package:chicki_buddy/services/native_classifier.service.dart';

// class TfliteClassifierService {
//   static final TfliteClassifierService _instance =
//       TfliteClassifierService._internal();

//   factory TfliteClassifierService() {
//     return _instance;
//   }

//   TfliteClassifierService._internal();

//   Interpreter? _interpreter;
//   Map<String, int>? _vocab;
//   List<String>? _labels; // Index to Label mapping
//   bool _isLoaded = false;
//   final Logger _logger = Logger();

//   static const int _maxLength = 512;
//   static const String _modelPath = 'assets/models/model.tflite';
//   static const String _vocabPath = 'assets/models/vocab.txt';
//   // We can reuse the same intent mapping file location as the native one
//   static const String _labelPath = 'assets/models/intent_mapping.json';

//   Future<void> initialize() async {
//     if (_isLoaded) return;

//     try {
//       // 1. Load Model
//       _logger.d("Loading TFLite model from $_modelPath");
//       _interpreter = await Interpreter.fromAsset(_modelPath);
//       _logger.i("Model loaded successfully.");
      
//       // LOG TENSOR INFO
//       _interpreter!.getInputTensors().forEach((t) {
//          _logger.i("Input Tensor: name=${t.name}, shape=${t.shape}, type=${t.type}");
//       });
//       _interpreter!.getOutputTensors().forEach((t) {
//          _logger.i("Output Tensor: name=${t.name}, shape=${t.shape}, type=${t.type}");
//       });

//       // 2. Load Vocab
//       _logger.d("Loading Vocabulary from $_vocabPath");
//       final vocabString = await rootBundle.loadString(_vocabPath);
//       _vocab = {};
//       final lines = LineSplitter.split(vocabString).toList();
//       for (int i = 0; i < lines.length; i++) {
//         _vocab![lines[i].trim()] = i;
//       }
//       _logger.i("Vocab loaded with ${_vocab!.length} tokens.");

//       // 3. Load Labels (Intent Mapping)
//       final mappingString = await rootBundle.loadString(_labelPath);
//       final Map<String, dynamic> jsonMap = json.decode(mappingString);
//       // The json is "id": "label", but we need a list where index matches id.
//       // The keys in json are strings "0", "1", etc.
//       // Find max index to size list correctly
//       int maxInd = 0;
//       jsonMap.keys.forEach((k) {
//          int? v = int.tryParse(k);
//          if (v != null && v > maxInd) maxInd = v;
//       });
//       _labels = List.filled(maxInd + 1, "unknown");
      
//       jsonMap.forEach((key, value) {
//         final int index = int.parse(key);
//         if (index < _labels!.length) {
//           _labels![index] = value.toString();
//         }
//       });
//       _logger.i("Labels loaded. Max index: $maxInd. Count: ${_labels!.length}");

//       _isLoaded = true;
//     } catch (e) {
//       _logger.e("Error initializing TfliteClassifierService", error: e);
//       _isLoaded = false;
//     }
//   }

//   Future<String?> classify(String text) async {
//     if (!_isLoaded) {
//       await initialize();
//       if (!_isLoaded) return null;
//     }

//     try {
//       // 1. Tokenize
//       // Replicating TokenizerHelper.kt: split by space, lowercase, drop unknowns.
//       final List<int> tokens = [];
//       tokens.add(_vocab!['[CLS]']!); // Always start with CLS

//       final words = text.toLowerCase().split(' ');
//       for (final word in words) {
//         if (tokens.length >= _maxLength - 1) break; // Reserve space for SEP
//         if (_vocab!.containsKey(word)) {
//           tokens.add(_vocab![word]!);
//         } else {
//              // Drop unknown
//         }
//       }

//       tokens.add(_vocab!['[SEP]']!); // End with SEP

//       // Pad
//       final int padId = _vocab!['[PAD]'] ?? 0;
//       while (tokens.length < _maxLength) {
//         tokens.add(padId);
//       }
      
//       _logger.i("Tokens (first 20): ${tokens.take(20).toList()}");

//       // 2. Prepare Inputs
//       final inputTensors = _interpreter!.getInputTensors();
//       var inputs = List<Object>.filled(inputTensors.length, []);
      
//       for(int i=0; i<inputTensors.length; i++) {
//         final name = inputTensors[i].name.toLowerCase();
//         final type = inputTensors[i].type;
        
//         List<int> data;
//         if (name.contains('input_ids')) {
//           data = tokens;
//         } else if (name.contains('attention_mask')) {
//            data = List.generate(_maxLength, (idx) => (tokens[idx] != padId || tokens[idx] != 0) ? 1 : 0);
//            // Native logic: if (inputIds[i] != 0) 1 else 0. Assuming PAD is 0.
//            // Let's stick closer to native logic check:
//            // "if (i < inputIds.size && inputIds[i] != 0) 1L else 0L" -> implies if it is NOT PAD(0).
//            // My token list is fully padded. So just check != 0.
//            for(int k=0; k<_maxLength; k++) {
//               if (tokens[k] == 0) data[k] = 0; else data[k] = 1;
//            }
//         } else {
//            data = List.filled(_maxLength, 0); 
//         }
        
//         // Handle Types explicitly
//         // reshape [1, 512]
//         if (type == TensorType.int64) {
//              // For BatchDim=1, wrapping Int64List in a List usually works: [ Int64List ]
//              // This corresponds to [1, 512]
//              inputs[i] = [Int64List.fromList(data)];
//         } else {
//              // Int32
//              inputs[i] = [Int32List.fromList(data)];
//         }
//         _logger.i("Prepared Input $i ($name): First 10=${data.take(10).toList()} (Type match: $type)");
//       }

//       // 3. Output
//       final outputTensors = _interpreter!.getOutputTensors();
//       // Assuming 1 output
//       final outputShape = outputTensors[0].shape; // [1, 60]
//       final numLabels = outputShape[1];
      
//       // Output buffer: List of floats.
//       // We pass a pre-allocated buffer. 
//       // For [1, 60], it can be List<List<double>> or just List<double> flat?
//       // RunForMultipleInputs takes map of index -> data.
//       // If we pass List<List<double>> sized [1, 60], it fills it.
      
//       final outputBuffer = List.filled(1 * numLabels, 0.0).reshape([1, numLabels]);
//       final Map<int, Object> outputs = {0: outputBuffer};
      
//       _logger.i("Running Inference...");
//       _interpreter!.runForMultipleInputs(inputs, outputs);
//       _logger.i("Inference Done.");
      
//       // 4. Post-process
//       final List<dynamic> batchOutput = (outputs[0] as List);
//       final List<double> logits = List<double>.from(batchOutput[0]); // Get first batch item
      
//       // Log some logits
//       _logger.i("Logits (first 10): ${logits.take(10).toList()}");
//       _logger.i("Logits (max): ${logits.reduce(max)}");

//       // Apply Softmax
//       final probabilities = _softmax(logits);
//       _logger.i("Probs (max): ${probabilities.reduce(max)}");
      
//       // Argmax
//       int maxIndex = -1;
//       double maxVal = -double.infinity;
//       for (int i = 0; i < probabilities.length; i++) {
//         if (probabilities[i] > maxVal) {
//           maxVal = probabilities[i];
//           maxIndex = i;
//         }
//       }
      
//       final result = (maxIndex != -1 && maxIndex < _labels!.length) 
//          ? _labels![maxIndex] 
//          : "unknown($maxIndex)";
         
//       _logger.i("Prediction: $result");

//       return result;

//     } catch (e, stack) {
//       _logger.e("Error during classification", error: e, stackTrace: stack);
//       return null;
//     }
//   }
  
//   List<double> _softmax(List<double> logits) {
//     double maxLogit = logits.reduce(max);
//     List<double> expLogits = logits.map((l) => exp(l - maxLogit)).toList();
//     double sumExp = expLogits.reduce((a, b) => a + b);
//     return expLogits.map((l) => l / sumExp).toList();
//   }

//   void dispose() {
//     _interpreter?.close();
//   }
// }
