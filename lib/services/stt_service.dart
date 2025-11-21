import 'dart:async';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_utils.dart';
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

  AppConfigController? _appConfig;

  final SpeechToText _speech = SpeechToText();
  final _textController = StreamController<String>.broadcast();
  final _rmsController = StreamController<double>.broadcast();
  bool _isInitialized = false;
  String _lastRecognizedText = '';

  void setConfig(AppConfigController config) {
    _appConfig = config;
  }

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<void> initialize() async {
    try {
      await PermissionUtils.checkMicrophone();

      _isInitialized = await _speech.initialize(
        onError: (errorNotification) => {
          logger.error(
            'Speech recognition error: ${errorNotification.errorMsg}',
          ),
          stopListening()
        },
        onStatus: (status) => logger.info('Speech recognition status: $status'),
        debugLogging: true,
        // finalTimeout: const Duration(seconds: 20),
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
            _lastRecognizedText = result.recognizedWords;
            stopListening();
            logger.info('Final recognition result: $_lastRecognizedText');
          }
        },
        onSoundLevelChange: (level) {
          _rmsController.add(level);
        },
        // listenFor: const Duration(seconds: 30),
        // pauseFor: const Duration(seconds: 15),
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: _appConfig?.defaultLanguage.value ?? 'en_US',
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

      // Emit the final recognized text via event bus when listening stops
      eventBus.emit(AppEvent(AppEventType.assistantMessage, _lastRecognizedText));
      _textController.add(_lastRecognizedText);
      _lastRecognizedText = '';
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
