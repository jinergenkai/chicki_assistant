import 'package:flutter/services.dart';
import 'dart:convert';

class NativeClassifier {
  static const _channel = MethodChannel('intent_classifier');
  static Map<String, String>? _intentMapping;

  static Future<void> loadIntentMapping() async {
    if (_intentMapping != null) return;

    final String jsonString = await rootBundle.loadString('assets/models/intent_mapping.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _intentMapping = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<String?> classify(String text) async {
    await loadIntentMapping();
    final int? result = await _channel.invokeMethod<int>('classify', {"text": text});
    
    if (result == null) return null;
    return _intentMapping?[result.toString()];
  }
}
