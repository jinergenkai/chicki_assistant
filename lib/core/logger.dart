import 'package:flutter/foundation.dart';
import 'app_config.dart';

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  void debug(String message) {
    if (AppConfig().isDebugMode) {
      debugPrint('🐛 DEBUG: $message');
    }
  }

  void info(String message) {
    debugPrint('ℹ️ INFO: $message');
  }

  void warning(String message) {
    debugPrint('⚠️ WARNING: $message');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('❌ ERROR: $message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void success(String message) {
    debugPrint('✅ SUCCESS: $message');
  }
}

// Global logger instance for easy access
final logger = Logger();