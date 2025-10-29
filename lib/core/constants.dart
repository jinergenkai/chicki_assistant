import 'dart:ui';

class AppConstants {
  // Base URLs
  // static const String baseUrl = 'http://192.168.0.103:1337/v1';
  // static const String baseUrl = 'http://192.168.95.91:11434/v1';
  static const String baseUrl = 'http://huynhhanh.com:9443/api/v1';
  // static const String baseUrl = 'http://192.168.0.105:9443/api/v1';

  // API Keys
  static const String openAIKey = 'YOUR_OPENAI_KEY';
  static const String janKey = '1';

  // Isolate Names
  // Name constants to avoid typo
  static const String kBgTaskPortName = 'bg_task_port';
  static const String kForegroundPortName = 'foreground_port';

  
  // App Settings
  static const String appName = 'Voice AI Assistant';
  static const int maxRetries = 3;
  
  // Messages
  static const String listeningMessage = 'Listening...';
  static const String processingMessage = 'Processing...';
  static const String errorMessage = 'Something went wrong';

  static const Color backgroundColor = Color.fromARGB(255, 221, 230, 238); // light grey bg
  // static const Color backgroundColor = Color.fromARGB(255, 214, 222, 230); // light grey bg


  static const String promptTemplate = '''
Bạn là hệ thống phân tích ý định người dùng. Dưới đây là các intent hợp lệ:
- listBook: liệt kê danh sách sách
- selectBook: chọn sách, slot: bookName
- listTopic: liệt kê chủ đề
- selectTopic: chọn chủ đề, slot: topicName
- startConversation: bắt đầu hội thoại

Yêu cầu: Phân tích câu sau và trả về kết quả dạng JSON với intent và slots (nếu có).
Ví dụ:
Input: "Tôi muốn đọc sách Harry Potter"
Output: {"intent": "selectBook", "slots": {"bookName": "Harry Potter"}}
''';
}