import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import '../core/logger.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/gpt_service.dart';

enum VoiceState {
  uninitialized,
  needsPermission,
  idle,
  listening,
  processing,
  speaking,
  detecting,  // Added for wake word detection
  error
}

class VoiceController {
  static final VoiceController _instance = VoiceController._internal();
  factory VoiceController() => _instance;
  VoiceController._internal();

  final STTService _sttService = SpeechToTextService();
  String? _lastProcessedText;
  final TTSService _ttsService = TextToSpeechService();
  final GPTService _gptService = OpenAIService();
  PorcupineManager? _porcupineManager;

  bool _isInitialized = false;
  final bool _isWakeWordEnabled = false;
  final _stateController = StreamController<VoiceState>.broadcast();

  final _textController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();

  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get onTextRecognized => _textController.stream;
  Stream<String> get onGptResponse => _responseController.stream;
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
      
      // Initialize Porcupine wake word detection
      // try {
      //   _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
      //     "3ZsjB+Lqz9YvUxjiPBL8lktSfYU27+Dy3HXQlzObXf+9PhpXizlbkw==",
      //     // ["assets/hey_chicki.ppn"], // Custom wake word model file
      //       [BuiltInKeyword.PICOVOICE, BuiltInKeyword.PORCUPINE],
      //     _wakeWordCallback
      //   );
      //   _isWakeWordEnabled = true;
      //   logger.info('Wake word detection initialized');
      //   await _porcupineManager?.start();
      // } catch (e) {
      //   logger.error('Failed to initialize wake word detection', e);
      //   // Continue without wake word detection
      //   _isWakeWordEnabled = false;
      // }
      
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
        // Chặn duplicate message
        if (_lastProcessedText == text) {
          logger.info('Duplicate speech input detected, skipping: $text');
          return;
        }
        _lastProcessedText = text;
        try {
          // Emit recognized text
          _textController.add(text);
          
          _stateController.add(VoiceState.processing);
          logger.info('Processing speech input: $text');
          
          // Get response from GPT
          final response = await _gptService.generateResponse(text);
          logger.success('Got GPT response: $response');
          
          // Emit GPT response
          _responseController.add(response);
          
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
      logger.info('voice controller: Started listening');
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
      logger.info('voice controller: Stopped listening');
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
    // Không đóng các StreamController vì VoiceController là singleton và có thể còn được sử dụng ở nơi khác.
    // _stateController.close();
    // _textController.close();
    // _responseController.close();

    _porcupineManager?.delete();
  }

  void _wakeWordCallback(int keywordIndex) {
    logger.info('Wake word detected! Index: $keywordIndex');
    if (_stateController.isClosed) return;
    
    _stateController.add(VoiceState.detecting);
    startListening();
  }

  Future<void> startWakeWordDetection() async {
    if (!_isInitialized || !_isWakeWordEnabled) {
      throw Exception('Wake word detection not initialized');
    }

    try {
      await _porcupineManager?.start();
      logger.info('Started wake word detection');
    } catch (e) {
      logger.error('Error starting wake word detection', e);
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }

  Future<void> stopWakeWordDetection() async {
    if (!_isWakeWordEnabled) return;
    
    try {
      await _porcupineManager?.stop();
      logger.info('Stopped wake word detection');
    } catch (e) {
      logger.error('Error stopping wake word detection', e);
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }
}