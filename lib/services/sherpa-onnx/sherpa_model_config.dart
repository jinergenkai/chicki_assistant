// Copyright (c)  2024  Xiaomi Corporation

import "dart:io";

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import './sherpa_utils.dart';
import '../../core/logger.dart';

class SherpaModelConfig {
  /// Create OfflineTts instance with the specified model configuration
  static Future<sherpa_onnx.OfflineTts> createOfflineTts() async {
    try {
      // sherpa_onnx requires that model files are in the local disk, so we
      // need to copy all asset files to disk.
      await SherpaUtils.copyAllAssetFiles();

      sherpa_onnx.initBindings();

      // Configuration as specified in the task
      String modelDir = 'models/tts/vits-piper-en_US-amy-low';
      String modelName = 'en_US-amy-low.onnx';
      String dataDir = 'vits-piper-en_US-amy-low/espeak-ng-data';
      
      // Optional parameters
      String voices = ''; // for Kokoro only
      String ruleFsts = '';
      String ruleFars = '';
      String lexicon = '';
      String dictDir = '';

      if (modelName == '') {
        throw Exception(
            'You are supposed to select a model by changing the code before you run the app');
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

      if (lexicon.contains(',')) {
        final all = lexicon.split(',');
        var tmp = <String>[];
        for (final f in all) {
          tmp.add(p.join(directory.path, f));
        }
        lexicon = tmp.join(',');
      } else if (lexicon != '') {
        lexicon = p.join(directory.path, modelDir, lexicon);
      }

      if (dataDir != '') {
        dataDir = p.join(directory.path, dataDir);
      }

      if (dictDir != '') {
        dictDir = p.join(directory.path, dictDir);
      }

      final tokens = p.join(directory.path, modelDir, 'tokens.txt');
      if (voices != '') {
        voices = p.join(directory.path, modelDir, voices);
      }

      late final sherpa_onnx.OfflineTtsVitsModelConfig vits;
      late final sherpa_onnx.OfflineTtsKokoroModelConfig kokoro;

      if (voices != '') {
        vits = const sherpa_onnx.OfflineTtsVitsModelConfig();
        kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(
          model: modelName,
          voices: voices,
          tokens: tokens,
          dataDir: dataDir,
          dictDir: dictDir,
          lexicon: lexicon,
        );
      } else {
        vits = sherpa_onnx.OfflineTtsVitsModelConfig(
          model: modelName,
          lexicon: lexicon,
          tokens: tokens,
          dataDir: dataDir,
          dictDir: dictDir,
        );

        kokoro = const sherpa_onnx.OfflineTtsKokoroModelConfig();
      }

      final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
        vits: vits,
        kokoro: kokoro,
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

      logger.info('Creating Sherpa-ONNX TTS with config: $modelDir - $modelName');

      final tts = sherpa_onnx.OfflineTts(config);
      logger.info('Sherpa-ONNX TTS created successfully');

      return tts;
    } catch (e) {
      logger.error('Failed to create Sherpa-ONNX TTS: $e');
      rethrow;
    }
  }

  /// Get model information
  static Map<String, String> getModelInfo() {
    return {
      'modelDir': 'models/tts/vits-piper-en_US-amy-low',
      'modelName': 'en_US-amy-low.onnx',
      'dataDir': 'vits-piper-en_US-amy-low/espeak-ng-data',
      'description': 'VITS Piper English US Amy Low Quality TTS Model'
    };
  }

  /// Check if model files exist
  static Future<bool> checkModelFiles() async {
    try {
      final Directory directory = await getApplicationSupportDirectory();
      const modelDir = 'models/tts/vits-piper-en_US-amy-low';
      const modelName = 'en_US-amy-low.onnx';
      const dataDir = 'vits-piper-en_US-amy-low/espeak-ng-data';
      
      final modelPath = p.join(directory.path, modelDir, modelName);
      final dataPath = p.join(directory.path, dataDir);
      final tokensPath = p.join(directory.path, modelDir, 'tokens.txt');
      
      final modelExists = await SherpaUtils.fileExists(modelPath);
      final dataExists = await SherpaUtils.fileExists(dataPath);
      final tokensExists = await SherpaUtils.fileExists(tokensPath);
      
      logger.info('Model files check - Model: $modelExists, Data: $dataExists, Tokens: $tokensExists');
      
      return modelExists && dataExists && tokensExists;
    } catch (e) {
      logger.error('Error checking model files: $e');
      return false;
    }
  }
}