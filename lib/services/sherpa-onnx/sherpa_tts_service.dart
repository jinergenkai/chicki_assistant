// Copyright (c)  2024  Xiaomi Corporation
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:get/get.dart';

import './sherpa_model_config.dart';
import './sherpa_utils.dart';
import '../tts_service.dart';
import '../../controllers/app_config.controller.dart';
import '../../core/logger.dart';

class SherpaTtsService implements TTSService {
  static final SherpaTtsService _instance = SherpaTtsService._internal();
  factory SherpaTtsService() => _instance;
  SherpaTtsService._internal();

  sherpa_onnx.OfflineTts? _tts;
  late final AudioPlayer _player;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _lastFilename = '';
  int _maxSpeakerID = 0;
  double _speed = 1.0;
  
  final _config = Get.find<AppConfigController>();

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        logger.info('Sherpa-ONNX TTS already initialized');
        return;
      }

      logger.info('Initializing Sherpa-ONNX TTS...');

      // Initialize bindings
      sherpa_onnx.initBindings();

      // Initialize audio player
      _player = AudioPlayer();

      // Setup audio player event listeners
      _setupAudioPlayerListeners();

      // Create the TTS model
      _tts = await SherpaModelConfig.createOfflineTts();

      if (_tts == null) {
        throw Exception('Failed to create Sherpa-ONNX TTS instance');
      }

      // Set initial speed from config
      _speed = _config.speechRate.value;

      // Get max speaker ID
      _maxSpeakerID = _tts?.numSpeakers ?? 0;
      if (_maxSpeakerID > 0) {
        _maxSpeakerID -= 1;
      }

      _isInitialized = true;
      logger.info('Sherpa-ONNX TTS initialized successfully. Max speakers: $_maxSpeakerID');
    } catch (e) {
      logger.error('Failed to initialize Sherpa-ONNX TTS service', e);
      _isInitialized = false;
      rethrow;
    }
  }

  void _setupAudioPlayerListeners() {
    _player.onPlayerStateChanged.listen((PlayerState state) {
      switch (state) {
        case PlayerState.playing:
          _isSpeaking = true;
          logger.info('Sherpa TTS: Started playing audio');
          break;
        case PlayerState.paused:
        case PlayerState.stopped:
        case PlayerState.completed:
          _isSpeaking = false;
          logger.info('Sherpa TTS: Audio playback finished');
          break;
        case PlayerState.disposed:
          _isSpeaking = false;
          logger.info('Sherpa TTS: Audio player disposed');
          break;
      }
    });

    _player.onPlayerComplete.listen((event) {
      _isSpeaking = false;
      logger.info('Sherpa TTS: Audio playback completed');
    });
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('Sherpa-ONNX TTS Service not initialized');
    }

    if (_tts == null) {
      throw Exception('Sherpa-ONNX TTS instance is null');
    }

    try {
      // Stop any current playback
      if (_isSpeaking) {
        await stop();
      }

      final cleanText = text.trim();
      if (cleanText.isEmpty) {
        logger.warning('Empty text provided for TTS');
        return;
      }

      logger.info('Generating speech for: $cleanText');

      final stopwatch = Stopwatch();
      stopwatch.start();

      if (_tts == null) {
        throw Exception('Sherpa-ONNX TTS instance is null');
      }
      // Generate audio using Sherpa-ONNX
      final audio = _tts!.generate(
        text: cleanText, 
        sid: 0, // Use speaker 0 as default
        speed: _speed
      );
      
      final suffix = '-sid-0-speed-${_speed.toStringAsPrecision(2)}';
      final filename = await SherpaUtils.generateWaveFilename(suffix);

      // Write audio to file
      final ok = sherpa_onnx.writeWave(
        filename: filename,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );

      if (ok) {
        stopwatch.stop();
        double elapsed = stopwatch.elapsed.inMilliseconds.toDouble();
        double waveDuration = audio.samples.length.toDouble() / audio.sampleRate.toDouble();

        logger.info('Sherpa TTS generated audio: '
            'File: $filename, '
            'Elapsed: ${(elapsed / 1000).toStringAsPrecision(4)}s, '
            'Duration: ${waveDuration.toStringAsPrecision(4)}s, '
            'RTF: ${(elapsed / 1000 / waveDuration).toStringAsPrecision(3)}');

        _lastFilename = filename;

        // Play the generated audio
        await _player.play(DeviceFileSource(_lastFilename));
        _isSpeaking = true;
      } else {
        throw Exception('Failed to save generated audio');
      }
    } catch (e) {
      _isSpeaking = false;
      logger.error('Error while speaking with Sherpa-ONNX', e);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      _isSpeaking = false;
      logger.info('Stopped Sherpa-ONNX TTS playback');
    } catch (e) {
      logger.error('Error while stopping Sherpa-ONNX TTS', e);
      rethrow;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    // Sherpa-ONNX TTS models are language-specific, so this is mainly for compatibility
    logger.info('Sherpa-ONNX TTS: Language setting not directly supported.');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      // Clamp the rate to reasonable bounds
      _speed = rate.clamp(0.5, 3.0);
      logger.info('Set Sherpa-ONNX TTS speech rate to: $_speed');
    } catch (e) {
      logger.error('Error while setting speech rate', e);
      rethrow;
    }
  }

  /// Set the speaker ID (if model supports multiple speakers)
  Future<void> setSpeakerId(int speakerId) async {
    if (speakerId < 0 || speakerId > _maxSpeakerID) {
      throw ArgumentError('Speaker ID $speakerId is out of range (0-$_maxSpeakerID)');
    }
    logger.info('Speaker ID set to: $speakerId');
  }

  /// Get the number of available speakers
  int get numSpeakers => _maxSpeakerID + 1;

  /// Play the last generated audio file
  Future<void> playLast() async {
    if (_lastFilename.isEmpty) {
      logger.warning('No generated audio file to play');
      return;
    }

    try {
      await _player.stop();
      await _player.play(DeviceFileSource(_lastFilename));
      logger.info('Playing last generated audio: $_lastFilename');
    } catch (e) {
      logger.error('Error playing last audio: $e');
      rethrow;
    }
  }

  /// Check if the service is ready to use
  bool get isReady => _isInitialized && _tts != null;

  /// Get current speech speed
  double get speechSpeed => _speed;

  Future<void> dispose() async {
    try {
      _isSpeaking = false;
      await _player.stop();
      await _player.dispose();
      _tts?.free();
      _isInitialized = false;
      logger.info('Sherpa-ONNX TTS service disposed');
    } catch (e) {
      logger.error('Error disposing Sherpa-ONNX TTS service: $e');
    }
  }
}