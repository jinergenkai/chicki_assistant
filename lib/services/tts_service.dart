import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/logger.dart';
import 'package:get/get.dart';
import '../controllers/app_config.controller.dart';

abstract class TTSService {
  Future<void> initialize();
  Future<void> speak(String text);
  Future<void> stop();
  bool get isSpeaking;
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
}

class TextToSpeechService implements TTSService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  final _config = Get.find<AppConfigController>();

  @override
  bool get isSpeaking => _isSpeaking;
  bool _isSpeaking = false;

  @override
  Future<void> initialize() async {
    try {
      // Set initial configuration
      await _tts.setLanguage(_config.defaultLanguage.value);
      await _tts.setSpeechRate(_config.speechRate.value);

      // await _tts.setVoice({"name": "en-US-Wavenet-D", "locale": "en-US"});
      // List<dynamic> voices = await _tts.getVoices;
      // print("Available voices: $voices");

      await _tts.setVoice({"name": "Google UK English Female", "locale": "en-GB"});

      await _tts.setVolume(1.0);
      await _tts.setPitch(1.2);

      // Set completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        logger.info('Finished speaking');
      });

      // Set error handler
      _tts.setErrorHandler((message) {
        _isSpeaking = false;
        logger.error('TTS error: $message');
      });

      // Set progress handler
      _tts.setProgressHandler((text, start, end, word) {
        logger.info('Speaking word: $word ($start/$end)');
      });

      // Check if the language is available
      final available = await _tts.isLanguageAvailable(_config.defaultLanguage.value);
      if (!available) {
        logger.warning('Language ${_config.defaultLanguage.value} not available, falling back to en-US');
        await _tts.setLanguage('en-US');
      }

      _isInitialized = true;
      logger.info('Text-to-Speech service initialized');
    } catch (e) {
      logger.error('Failed to initialize Text-to-Speech service', e);
      rethrow;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('TTS Service not initialized');
    }

    try {
      if (_isSpeaking) {
        await stop();
      }

      _isSpeaking = true;
      logger.info('Speaking: $text');
      
      final result = await _tts.speak(text);
      if (result != 1) {
        throw Exception('Failed to start speaking');
      }
    } catch (e) {
      _isSpeaking = false;
      logger.error('Error while speaking', e);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      final result = await _tts.stop();
      _isSpeaking = false;
      logger.info('Stopped speaking');
      
      if (result != 1) {
        throw Exception('Failed to stop speaking');
      }
    } catch (e) {
      logger.error('Error while stopping speech', e);
      rethrow;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      final available = await _tts.isLanguageAvailable(language);
      if (!available) {
        throw Exception('Language $language not available');
      }

      await _tts.setLanguage(language);
      logger.info('Set language to: $language');
    } catch (e) {
      logger.error('Error while setting language', e);
      rethrow;
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
      logger.info('Set speech rate to: $rate');
    } catch (e) {
      logger.error('Error while setting speech rate', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    _isSpeaking = false;
    await _tts.stop();
  }
}