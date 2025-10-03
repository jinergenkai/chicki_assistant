// Dart
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';

class PermissionUtils {
  /// Checks and requests microphone permission.
  static Future<bool> checkMicrophone() async {
    try {
      PermissionStatus micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) {
        micStatus = await Permission.microphone.request();
      }
      if (micStatus.isPermanentlyDenied || !micStatus.isGranted) {
        logger.error('Microphone permission not granted or permanently denied');
        return false;
      }
      return true;
    } catch (e) {
      logger.error('Exception in checkMicrophone', e);
      return false;
    }
  }

  /// Checks and requests notification permission.
  static Future<bool> checkNotification() async {
    try {
      PermissionStatus status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied || !status.isGranted) {
        logger.error('Notification permission not granted or permanently denied');
        return false;
      }
      return true;
    } catch (e) {
      logger.error('Exception in checkNotification', e);
      return false;
    }
  }

  /// Checks and requests storage permission.
  static Future<bool> checkStorage() async {
    try {
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        logger.error('Storage permission not granted or permanently denied');
        return false;
      }
      return true;
    } catch (e) {
      logger.error('Exception in checkStorage', e);
      return false;
    }
  }
}