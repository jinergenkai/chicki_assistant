import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';
import 'stt_service.dart';
import 'tts_service.dart';
import 'gpt_service.dart';

enum VoiceState {
  uninitialized,
  needsPermission,
  idle,
  listening,
  processing,
  speaking,
  error
}

class VoiceController {
  static final VoiceController _instance = VoiceController._internal();
  factory VoiceController() => _instance;
  VoiceController._internal();

  final STTService _sttService = SpeechToTextService();
  final TTSService _ttsService = TextToSpeechService();
  final GPTService _gptService = OpenAIService();

  bool _isInitialized = false;
  final _stateController = StreamController<VoiceState>.broadcast();

  Stream<VoiceState> get stateStream => _stateController.stream;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _stateController.add(VoiceState.uninitialized);

      // Check microphone permission first
      final micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) {
        _stateController.add(VoiceState.needsPermission);
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          throw Exception('Microphone permission denied');
        }
      }

      // Initialize all services
      await _sttService.initialize();
      await _ttsService.initialize();
      await _gptService.initialize();
      
      _setupSTTListener();
      _isInitialized = true;
      
      logger.info('Voice Controller initialized successfully');
      _stateController.add(VoiceState.idle);
    } catch (e) {
      logger.error('Failed to initialize Voice Controller', e);
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }

  void _setupSTTListener() {
    _sttService.onTextRecognized.listen((text) async {
      if (text.isNotEmpty) {
        try {
          _stateController.add(VoiceState.processing);
          logger.info('Processing speech input: $text');
          
          // Get response from GPT
          final response = await _gptService.generateResponse(text);
          logger.info('Got GPT response: $response');
          
          // Speak the response
          _stateController.add(VoiceState.speaking);
          await _ttsService.speak(response);
          
          _stateController.add(VoiceState.idle);
        } catch (e) {
          logger.error('Error processing voice input', e);
          _stateController.add(VoiceState.error);
        }
      }
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('Voice Controller not initialized');
    }
    
    try {
      // Double check microphone permission
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        _stateController.add(VoiceState.needsPermission);
        throw Exception('Microphone permission not granted');
      }

      await _sttService.startListening();
      _stateController.add(VoiceState.listening);
      logger.info('Started listening');
    } catch (e) {
      logger.error('Error starting voice listening', e);
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      await _sttService.stopListening();
      _stateController.add(VoiceState.idle);
      logger.info('Stopped listening');
    } catch (e) {
      logger.error('Error stopping voice listening', e);
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _ttsService.stop();
      _stateController.add(VoiceState.idle);
      logger.info('Stopped speaking');
    } catch (e) {
      logger.error('Error stopping speech', e);
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }

  void dispose() {
    _stateController.close();
  }
}