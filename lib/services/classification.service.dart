import 'package:tflite_flutter/tflite_flutter.dart';

void runModel() async {
  final interpreter = await Interpreter.fromAsset('model.tflite');

  // chuẩn bị input
  var input = [ [0.1, 0.2, 0.3] ]; // ví dụ
  var output = List.filled(1 * 3, 0).reshape([1, 3]);

  interpreter.run(input, output);

  print("Kết quả: $output");
}
