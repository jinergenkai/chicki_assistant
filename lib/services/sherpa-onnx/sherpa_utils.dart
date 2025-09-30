// Copyright (c)  2024  Xiaomi Corporation
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/logger.dart';

class SherpaUtils {
  /// Generate a unique wave filename with optional suffix
  static Future<String> generateWaveFilename([String suffix = '']) async {
    final Directory directory = await getApplicationSupportDirectory();
    DateTime now = DateTime.now();
    final filename =
        '${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}$suffix.wav';

    return p.join(directory.path, filename);
  }

  /// Get all asset files from the asset manifest
  static Future<List<String>> getAllAssetFiles() async {
    try {
      final AssetManifest assetManifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> assets = assetManifest.listAssets();
      logger.info('list all asset files: $assets');
      return assets;
    } catch (e) {
      logger.error('Error getting asset files: $e');
      return [];
    }
  }

  /// Strip leading directory from path
  static String stripLeadingDirectory(String src, {int n = 1}) {
    return p.joinAll(p.split(src).sublist(n));
  }

  /// Copy all asset files to local storage
  static Future<void> copyAllAssetFiles() async {
    try {
      final allFiles = await getAllAssetFiles();
      for (final src in allFiles) {
        final dst = stripLeadingDirectory(src);
        await copyAssetFile(src, dst);
      }
      logger.info('All asset files copied successfully');
    } catch (e) {
      logger.error('Error copying asset files: $e');
      rethrow;
    }
  }

  /// Copy the asset file from src to dst.
  /// If dst already exists, then just skip the copy
  static Future<String> copyAssetFile(String src, [String? dst]) async {
    try {
      final Directory directory = await getApplicationSupportDirectory();
      dst ??= p.basename(src);
      final target = p.join(directory.path, dst);
      bool exists = await File(target).exists();

      final data = await rootBundle.load(src);
      if (!exists || File(target).lengthSync() != data.lengthInBytes) {
        final List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await (await File(target).create(recursive: true)).writeAsBytes(bytes);
        // logger.info('Copied asset file: $src -> $target');
      } else {
        // logger.info('Asset file already exists: $target');
      }

      return target;
    } catch (e) {
      logger.error('Error copying asset file $src: $e');
      rethrow;
    }
  }

  /// Get application support directory path
  static Future<String> getAppSupportDirectoryPath() async {
    final Directory directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  /// Check if a file exists at the given path
  static Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      logger.error('Error checking file existence for $path: $e');
      return false;
    }
  }

  /// Create directory if it doesn't exist
  static Future<void> ensureDirectoryExists(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        logger.info('Created directory: $dirPath');
      }
    } catch (e) {
      logger.error('Error creating directory $dirPath: $e');
      rethrow;
    }
  }
}