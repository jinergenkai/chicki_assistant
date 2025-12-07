import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum AttachmentType { photo, audio }

class AttachmentService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Get the attachments directory for a specific entry
  Future<Directory> _getEntryAttachmentsDir(String bookId, String entryId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(
      path.join(appDir.path, 'journal_attachments', bookId, entryId),
    );

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    return attachmentsDir;
  }

  /// Pick image from gallery
  Future<String?> pickImageFromGallery(String bookId, String entryId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _saveAttachment(
        File(image.path),
        bookId,
        entryId,
        AttachmentType.photo,
      );
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take photo with camera
  Future<String?> takePhoto(String bookId, String entryId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _saveAttachment(
        File(image.path),
        bookId,
        entryId,
        AttachmentType.photo,
      );
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick multiple images
  Future<List<String>> pickMultipleImages(String bookId, String entryId) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      List<String> paths = [];
      for (var image in images) {
        final savedPath = await _saveAttachment(
          File(image.path),
          bookId,
          entryId,
          AttachmentType.photo,
        );
        if (savedPath != null) {
          paths.add(savedPath);
        }
      }

      return paths;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  /// Save attachment to app directory
  Future<String?> _saveAttachment(
    File sourceFile,
    String bookId,
    String entryId,
    AttachmentType type,
  ) async {
    try {
      final attachmentsDir = await _getEntryAttachmentsDir(bookId, entryId);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourceFile.path);

      String prefix;
      switch (type) {
        case AttachmentType.photo:
          prefix = 'photo';
          break;
        case AttachmentType.audio:
          prefix = 'voice';
          break;
      }

      final fileName = '${prefix}_$timestamp$extension';
      final targetPath = path.join(attachmentsDir.path, fileName);
      final targetFile = await sourceFile.copy(targetPath);

      return targetFile.path;
    } catch (e) {
      print('Error saving attachment: $e');
      return null;
    }
  }

  /// Save audio recording
  Future<String?> saveAudioRecording(
    String recordingPath,
    String bookId,
    String entryId,
  ) async {
    try {
      return await _saveAttachment(
        File(recordingPath),
        bookId,
        entryId,
        AttachmentType.audio,
      );
    } catch (e) {
      print('Error saving audio recording: $e');
      return null;
    }
  }

  /// Delete attachment
  Future<bool> deleteAttachment(String attachmentPath) async {
    try {
      final file = File(attachmentPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting attachment: $e');
      return false;
    }
  }

  /// Delete all attachments for an entry
  Future<void> deleteAllEntryAttachments(String bookId, String entryId) async {
    try {
      final attachmentsDir = await _getEntryAttachmentsDir(bookId, entryId);
      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting entry attachments: $e');
    }
  }

  /// Get photo paths from attachments list
  List<String> getPhotoPaths(List<String>? attachments) {
    if (attachments == null) return [];
    return attachments.where((path) {
      final ext = path.toLowerCase();
      return ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png') ||
          ext.endsWith('.gif') ||
          ext.endsWith('.webp');
    }).toList();
  }

  /// Get audio paths from attachments list
  List<String> getAudioPaths(List<String>? attachments) {
    if (attachments == null) return [];
    return attachments.where((path) {
      final ext = path.toLowerCase();
      return ext.endsWith('.m4a') ||
          ext.endsWith('.aac') ||
          ext.endsWith('.mp3') ||
          ext.endsWith('.wav') ||
          ext.endsWith('.ogg');
    }).toList();
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
