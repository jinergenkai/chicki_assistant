// Copyright (c)  2024  Xiaomi Corporation
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:get/get.dart';

import './sherpa_utils.dart';
import '../tts_service.dart';
import '../../controllers/app_config.controller.dart';
import '../../core/logger.dart';

class _IsolateTask<T> {
  final SendPort sendPort;
  RootIsolateToken? rootIsolateToken;

  _IsolateTask(this.sendPort, this.rootIsolateToken);
}

class _PortModel {
  final String method;
  final SendPort? sendPort;
  dynamic data;

  _PortModel({
    required this.method,
    this.sendPort,
    this.data,
  });
}

class _TtsManager {
  /// Main process communication port
  final ReceivePort receivePort;
  final Isolate isolate;
  final SendPort isolatePort;

  _TtsManager({
    required this.receivePort,
    required this.isolate,
    required this.isolatePort,
  });
}

class SherpaIsolateTtsService implements TTSService {
  static final SherpaIsolateTtsService _instance = SherpaIsolateTtsService._internal();
  factory SherpaIsolateTtsService() => _instance;
  SherpaIsolateTtsService._internal();

  static late final _TtsManager _ttsManager;
  static bool _isInitialized = false;
  static bool _isSpeaking = false;

  final _config = Get.find<AppConfigController>();

  /// Get communication port to isolate
  static SendPort get _sendPort => _ttsManager.isolatePort;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.info('Sherpa Isolate TTS already initialized');
      return;
    }

    try {
      logger.info('Initializing Sherpa Isolate TTS...');
      if (await Permission.audio.isDenied || await Permission.audio.isPermanentlyDenied) {
        final state = await Permission.audio.request();
        if (!state.isGranted) {
          await SystemNavigator.pop();
        }
      }
      if (await Permission.storage.isDenied || await Permission.storage.isPermanentlyDenied) {
        final state = await Permission.storage.request();
        if (!state.isGranted) {
          await SystemNavigator.pop();
        }
      }

      ReceivePort port = ReceivePort();
      RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;

      Isolate isolate = await Isolate.spawn(
        _isolateEntry,
        _IsolateTask(port.sendPort, rootIsolateToken),
        errorsAreFatal: false,
      );

      // Wait for isolate to send back its SendPort
      await for (var msg in port) {
        if (msg is SendPort) {
          _ttsManager = _TtsManager(receivePort: port, isolate: isolate, isolatePort: msg);
          _isInitialized = true;
          logger.info('Sherpa Isolate TTS initialized successfully');
          break;
        }
      }
    } catch (e) {
      logger.error('Failed to initialize Sherpa Isolate TTS: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static Future<void> _isolateEntry(_IsolateTask task) async {
    if (task.rootIsolateToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(task.rootIsolateToken!);
    }

    MediaKit.ensureInitialized();
    final player = Player();
    sherpa_onnx.initBindings();

    final receivePort = ReceivePort();
    task.sendPort.send(receivePort.sendPort);

    String modelDir = '';
    String modelName = '';
    String ruleFsts = '';
    String ruleFars = '';
    String lexicon = '';
    String dataDir = '';
    String dictDir = '';

    // Use the specified model configuration
    modelDir = 'vits-piper-en_US-amy-low';
    modelName = 'en_US-amy-low.onnx';
    dataDir = 'vits-piper-en_US-amy-low/espeak-ng-data';

    if (modelName == '') {
      throw Exception('Model not configured properly');
    }

    final Directory directory = await getApplicationSupportDirectory();
    modelName = p.join(directory.path, modelDir, modelName);

    if (ruleFsts != '') {
      final all = ruleFsts.split(',');
      var tmp = <String>[];
      for (final f in all) {
        tmp.add(p.join(directory.path, f));
      }
      ruleFsts = tmp.join(',');
    }

    if (ruleFars != '') {
      final all = ruleFars.split(',');
      var tmp = <String>[];
      for (final f in all) {
        tmp.add(p.join(directory.path, f));
      }
      ruleFars = tmp.join(',');
    }

    if (lexicon != '') {
      lexicon = p.join(directory.path, modelDir, lexicon);
    }

    if (dataDir != '') {
      dataDir = p.join(directory.path, dataDir);
    }

    if (dictDir != '') {
      dictDir = p.join(directory.path, dictDir);
    }

    final tokens = p.join(directory.path, modelDir, 'tokens.txt');

    final vits = sherpa_onnx.OfflineTtsVitsModelConfig(
      model: modelName,
      lexicon: lexicon,
      tokens: tokens,
      dataDir: dataDir,
      dictDir: dictDir,
    );

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      vits: vits,
      numThreads: 2,
      debug: true,
      provider: 'cpu',
    );

    final config = sherpa_onnx.OfflineTtsConfig(
      model: modelConfig,
      ruleFsts: ruleFsts,
      ruleFars: ruleFars,
      maxNumSenetences: 1,
    );

    final tts = sherpa_onnx.OfflineTts(config);

    receivePort.listen((msg) async {
      if (msg is _PortModel) {
        switch (msg.method) {
          case 'generate':
            {
              _PortModel request = msg;
              final stopwatch = Stopwatch();
              stopwatch.start();

              final audio = tts.generate(text: request.data['text'], sid: request.data['sid'] ?? 0, speed: request.data['speed'] ?? 1.0);

              final suffix = '-sid-${request.data['sid']}-speed-${(request.data['speed'] ?? 1.0).toStringAsPrecision(2)}';
              final filename = await SherpaUtils.generateWaveFilename(suffix);

              final ok = sherpa_onnx.writeWave(
                filename: filename,
                samples: audio.samples,
                sampleRate: audio.sampleRate,
              );

              if (ok) {
                stopwatch.stop();
                double elapsed = stopwatch.elapsed.inMilliseconds.toDouble();
                double waveDuration = audio.samples.length.toDouble() / audio.sampleRate.toDouble();

                print('Sherpa Isolate TTS - Saved to $filename\n'
                    'Elapsed: ${(elapsed / 1000).toStringAsPrecision(4)} s\n'
                    'Wave duration: ${waveDuration.toStringAsPrecision(4)} s\n'
                    'RTF: ${(elapsed / 1000).toStringAsPrecision(4)}/${waveDuration.toStringAsPrecision(4)} '
                    '= ${(elapsed / 1000 / waveDuration).toStringAsPrecision(3)}');

                await player.open(Media('file:///$filename'));
                await player.play();
              }

              // Send completion signal back
              if (request.sendPort != null) {
                request.sendPort!.send({'status': ok ? 'success' : 'error'});
              }
            }
            break;

          case 'stop':
            {
              await player.stop();
              if (msg.sendPort != null) {
                msg.sendPort!.send({'status': 'stopped'});
              }
            }
            break;
        }
      }
    });
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('Sherpa Isolate TTS Service not initialized');
    }

    try {
      _isSpeaking = true;

      ReceivePort receivePort = ReceivePort();
      _sendPort.send(_PortModel(
        method: 'generate',
        data: {'text': text.trim(), 'sid': 0, 'speed': _config.speechRate.value},
        sendPort: receivePort.sendPort,
      ));

      // Wait for completion
      await receivePort.first;
      receivePort.close();
      _isSpeaking = false;

      logger.info('Sherpa Isolate TTS: Completed speaking "$text"');
    } catch (e) {
      _isSpeaking = false;
      logger.error('Error in Sherpa Isolate TTS speak: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      _isSpeaking = false;

      ReceivePort receivePort = ReceivePort();
      _sendPort.send(_PortModel(
        method: 'stop',
        sendPort: receivePort.sendPort,
      ));

      await receivePort.first;
      receivePort.close();

      logger.info('Sherpa Isolate TTS: Stopped');
    } catch (e) {
      logger.error('Error stopping Sherpa Isolate TTS: $e');
      rethrow;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    // Sherpa-ONNX TTS models are language-specific
    logger.info('Sherpa Isolate TTS: Language setting not supported for current model');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // Speech rate will be applied on next speak call
    logger.info('Sherpa Isolate TTS: Speech rate will be applied on next speak: $rate');
  }

  Future<void> dispose() async {
    try {
      if (_isInitialized) {
        _ttsManager.isolate.kill(priority: Isolate.immediate);
        _ttsManager.receivePort.close();
        _isInitialized = false;
        _isSpeaking = false;
        logger.info('Sherpa Isolate TTS: Disposed');
      }
    } catch (e) {
      logger.error('Error disposing Sherpa Isolate TTS: $e');
    }
  }
}
