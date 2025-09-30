import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:chicki_buddy/utils/file.dart';
import 'package:flutter/services.dart';
import '../core/logger.dart';
import 'package:get/get.dart';
import '../controllers/app_config.controller.dart';
import 'tts_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';

class SherpaTTSService implements TTSService {
  static final SherpaTTSService _instance = SherpaTTSService._internal();
  factory SherpaTTSService() => _instance;
  SherpaTTSService._internal();

  final _config = Get.find<AppConfigController>();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  late sherpa_onnx.OfflineTts _tts;
  late final AudioPlayer _player;
  String? _currentTempFile;
  
  // Model directory structure should match Piper model requirements
  static const String _modelDir = 'assets/models/tts/en_GB-jenny_dioco-medium';
  static const String _modelName = 'en_GB-jenny_dioco-medium.onnx';
  static const String _modelConfigName = 'en_GB-jenny_dioco-medium.onnx.json';
  static const String _tokensName = 'tokens.txt';
  static const String _dataDirName = 'espeak-ng-data';

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Initialize sherpa bindings and audio player
      sherpa_onnx.initBindings();
      _player = AudioPlayer();

      // Setup model paths
      final appDir = await getApplicationSupportDirectory();
      logger.info('App support directory: ${appDir.path}');
      final modelDirPath = p.join(appDir.path, _modelDir);
      final modelPath = p.join(modelDirPath, _modelName);
      final configPath = p.join(modelDirPath, _modelConfigName);
      final tokensPath = p.join(modelDirPath, _tokensName);
      final dataDirPath = p.join(modelDirPath, _dataDirName);

      // Create model directory if not exists
      final modelDir = Directory(modelDirPath);
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      // Copy model files to local storage
      await copyModelFiles();
      logger.info('Model files copied successfully');

      // Verify espeak-ng-data directory
      final espeakDir = Directory(dataDirPath);
      if (!await espeakDir.exists()) {
        throw Exception('espeak-ng-data directory not found at: $dataDirPath');
      }
      logger.info('espeak-ng-data directory verified');

      // Read config from json
      final configJson = await _readJsonFile(configPath);
      
      // Create tokens.txt from phoneme_id_map in config
      await _createTokensFile(configJson['phoneme_id_map'], tokensPath);

      // Setup VITS config with parameters from config file
      // Setup VITS config with parameters from config file and espeak-ng-data
      // Setup VITS config for Piper model - requires espeak-ng-data
      final vits = sherpa_onnx.OfflineTtsVitsModelConfig(
        model: modelPath,
        tokens: tokensPath,
        dataDir: dataDirPath, // espeak-ng-data directory path
        lexicon: "",
      );

      logger.info('Model paths:');
      logger.info('Model: $modelPath');
      logger.info('Config: $configPath');
      logger.info('Tokens: $tokensPath');
      logger.info('Data dir: $dataDirPath');
      logger.info('Dict dir: $modelDirPath');

      // Setup model config with debug mode for more info
      final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
        vits: vits,
        numThreads: 1,
        debug: true, // Enable debug for detailed logs
        provider: 'cpu',
      );

      // Create TTS instance
      final config = sherpa_onnx.OfflineTtsConfig(
        model: modelConfig,
        maxNumSenetences: 1,
      );

      try {
        _tts = sherpa_onnx.OfflineTts(config);
      } catch (e) {
        logger.error('Error creating OfflineTts instance', e);
        rethrow;
      }

      // Listen to audio player state changes
      _player.onPlayerComplete.listen((_) {
        _isSpeaking = false;
        _cleanupTempFile();
      });

      _isInitialized = true;
      logger.info('Sherpa TTS service initialized');
    } catch (e) {
      logger.error('Failed to initialize Sherpa TTS service', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _readJsonFile(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    return json.decode(content);
  }

  Future<void> _createTokensFile(Map<String, dynamic> phonemeMap, String outputPath) async {
    final file = File(outputPath);
    final sink = file.openWrite();
    try {
      for (var entry in phonemeMap.entries) {
        sink.writeln('${entry.key}\t${entry.value[0]}');
      }
    } finally {
      await sink.close();
    }
  }

  // Copy model-specific files while preserving directory structure
  Future<void> copyModelFiles() async {
    const modelAssetPath = 'assets/models/tts/en_GB-jenny_dioco-medium';
    final appDir = await getApplicationSupportDirectory();
    final modelTargetPath = p.join(appDir.path, _modelDir);

    // Create model directory
    await Directory(modelTargetPath).create(recursive: true);

    // Copy model files
    await copyAssetFile('$modelAssetPath/$_modelName', p.join(_modelDir, _modelName));
    await copyAssetFile('$modelAssetPath/$_modelConfigName', p.join(_modelDir, _modelConfigName));
    await copyAssetFile('$modelAssetPath/$_tokensName', p.join(_modelDir, _tokensName));

    // Copy espeak-ng-data directory with structure preserved
    const espeakAssetPath = '$modelAssetPath/$_dataDirName';
    final espeakTargetPath = p.join(modelTargetPath, _dataDirName);
    
    await Directory(espeakTargetPath).create(recursive: true);
    
    // Copy all espeak-ng-data files preserving structure
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifest);
    
    for (String key in manifestMap.keys) {
      if (key.startsWith(espeakAssetPath)) {
        final relativePath = key.substring(espeakAssetPath.length + 1);
        final targetFile = p.join(espeakTargetPath, relativePath);
        await Directory(p.dirname(targetFile)).create(recursive: true);
        await copyAssetFile(key, p.join(_modelDir, _dataDirName, relativePath));
      }
    }
  }

  void _cleanupTempFile() {
    if (_currentTempFile != null) {
      try {
        final file = File(_currentTempFile!);
        if (file.existsSync()) {
          file.deleteSync();
        }
        _currentTempFile = null;
      } catch (e) {
        logger.error('Error cleaning up temp file', e);
      }
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('Sherpa TTS Service not initialized');
    }

    try {
      if (_isSpeaking) {
        await stop();
      }

      _isSpeaking = true;
      logger.info('Speaking with Sherpa: $text');

      // Generate audio
      final audio = _tts.generate(
        text: text, 
        sid: 0, 
        
        speed: _config.speechRate.value
      );

      // Cleanup previous temp file if exists
      _cleanupTempFile();

      // Get temp file for wave output
      final tempDir = await getTemporaryDirectory();
      _currentTempFile = p.join(tempDir.path, 'sherpa_${DateTime.now().millisecondsSinceEpoch}.wav');

      // Save and play audio
      final ok = sherpa_onnx.writeWave(
        filename: _currentTempFile!,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );

      if (!ok) {
        throw Exception('Failed to write audio data');
      }

      // Play the generated audio file
      await _player.play(DeviceFileSource(_currentTempFile!));

    } catch (e) {
      _isSpeaking = false;
      _cleanupTempFile();
      logger.error('Error while speaking with Sherpa', e);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_isSpeaking) {
        await _player.stop();
        _isSpeaking = false;
        _cleanupTempFile();
      }
      logger.info('Stopped Sherpa speaking');
    } catch (e) {
      logger.error('Error while stopping Sherpa speech', e);
      rethrow;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      if (language != 'en-GB') {
        throw Exception('Sherpa only supports en-GB language');
      }
      logger.info('Set Sherpa language to: $language');
    } catch (e) {
      logger.error('Error while setting Sherpa language', e);
      rethrow;
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      // Rate will be applied during audio generation
      logger.info('Set speech rate to: $rate');
    } catch (e) {
      logger.error('Error while setting Sherpa speech rate', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      _isSpeaking = false;
      await stop();
      _tts.free();
      await _player.dispose();
    }
  }
}