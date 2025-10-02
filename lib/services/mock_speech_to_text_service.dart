import 'dart:async';
import 'package:get/get.dart';
import '../core/app_event_bus.dart';
import 'stt_service.dart';

class MockSpeechToTextService implements STTService {
  static final MockSpeechToTextService _instance = MockSpeechToTextService._internal();
  factory MockSpeechToTextService() => _instance;
  MockSpeechToTextService._internal();

  final _textController = StreamController<String>.broadcast();
  final _rmsController = StreamController<double>.broadcast();
  Timer? _timer;
  bool _isListening = false;
  int _counter = 0;

  @override
  Future<void> initialize() async {
    // No-op for mock
  }

  @override
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final text = 'Hello chicky ${++_counter} at ${DateTime.now().toIso8601String()}';
      _textController.add(text);
      eventBus.emit(AppEvent(AppEventType.assistantMessage, text));
      _rmsController.add(0.5); // Mock RMS value
    });
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Stream<String> get onTextRecognized => _textController.stream;

  @override
  Stream<double> get onRmsChanged => _rmsController.stream;

  @override
  bool get isListening => _isListening;
}