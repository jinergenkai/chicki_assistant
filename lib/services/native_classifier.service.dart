import 'package:flutter/services.dart';

class NativeClassifier {
  static const _channel = MethodChannel('intent_classifier');

  static Future<String?> classify(String text) async {
    final result = await _channel.invokeMethod<String>('classify', {"text": text});
    return result;
  }
}
