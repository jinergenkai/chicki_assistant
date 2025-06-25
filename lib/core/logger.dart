import 'package:logger/logger.dart';
import 'app_config.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      colors: true,
      printEmojis: true,
    ),
  );

  void debug(String message) {
    if (AppConfig().isDebugMode) {
      _logger.d(message);
    }
  }

  void info(String message) {
    _logger.i(message);
  }

  void warning(String message) {
    _logger.w(message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void success(String message) {
    _logger.i('✅ $message');
  }
}

// Global logger instance for easy access
final logger = LoggerService();