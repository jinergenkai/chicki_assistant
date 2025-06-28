import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';
import '../controllers/app_config.controller.dart';

abstract class STTService {
  Future<void> initialize();
  Future<void> startListening();
  Future<void> stopListening();
  Stream<String> get onTextRecognized;
  Stream<double> get onRmsChanged;
  bool get isListening;
}

class SpeechToTextService implements STTService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  final AppConfigController _appConfig = Get.find<AppConfigController>();

  final SpeechToText _speech = SpeechToText();
  final _textController = StreamController<String>.broadcast();
  final _rmsController = StreamController<double>.broadcast();
  bool _isInitialized = false;

  @override
  bool get isListening => _speech.isListening;

  Future<bool> _checkPermissions() async {
    try {
      // Check microphone permission
      PermissionStatus micStatus = await Permission.microphone.status;
      
      if (micStatus.isDenied) {
        // Request microphone permission
        micStatus = await Permission.microphone.request();
      }

      if (micStatus.isPermanentlyDenied) {
        logger.error('Microphone permission permanently denied');
        return false;
      }

      if (!micStatus.isGranted) {
        logger.error('Microphone permission not granted');
        return false;
      }

      return true;
    } catch (e) {
      logger.error('Error checking permissions', e);
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    try {
      // First check permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        throw Exception('Required permissions not granted');
      }

      _isInitialized = await _speech.initialize(
        onError: (errorNotification) => logger.error(
          'Speech recognition error: ${errorNotification.errorMsg}',
        ),
        onStatus: (status) => logger.info('Speech recognition status: $status'),
        debugLogging: true,
      );

      if (_isInitialized) {
        logger.info('Speech-to-Text service initialized');
      } else {
        throw Exception('Failed to initialize speech recognition');
      }
    } catch (e) {
      logger.error('Failed to initialize Speech-to-Text service', e);
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('STT Service not initialized');
    }

    try {
      logger.info('Starting speech recognition...');
      
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final text = result.recognizedWords;
            logger.info('Final recognition result: $text');
            _textController.add(text);
          }
        },
        onSoundLevelChange: (level) {
          _rmsController.add(level);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: _appConfig.defaultLanguage.value, 
      );

      logger.info('Started listening');
    } catch (e) {
      logger.error('Error while starting speech recognition', e);
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
      logger.info('Stopped listening');
    } catch (e) {
      logger.error('Error while stopping speech recognition', e);
      rethrow;
    }
  }

  @override
  Stream<String> get onTextRecognized => _textController.stream;

  @override
  Stream<double> get onRmsChanged => _rmsController.stream;

  void dispose() {
    _textController.close();
    _rmsController.close();
  }
}