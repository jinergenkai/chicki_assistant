import 'package:get/get.dart';
import 'package:hive/hive.dart';

class AppConfigController extends GetxController {
  static const String hiveBoxName = 'app_config';
  static const String hiveKey = 'config';

  // Các thuộc tính cấu hình
  // Debug/General
  var isDebugMode = true.obs;

  // API
  var apiEndpoint = 'https://api.openai.com/v1'.obs;
  var apiKey = ''.obs;

  // GPT/LLM
  var gptModel = 'gpt-3.5-turbo'.obs;
  var maxTokens = 150.obs;
  var temperature = 0.7.obs;
  var systemContext = ''.obs;

  // TTS/Speech
  var ttsEngine = 'flutter_tts'.obs;
  var speechRate = 0.9.obs;

  // Language/UI
  var defaultLanguage = 'en-US'.obs;
  var themeMode = 'system'.obs;
  var language = ''.obs;

  // Wakeword
  var enableWakewordBackground = false.obs;

  // ===== USER LEARNING DATA (for Dashboard & Analytics) =====
  // Recent Books Tracking
  var recentBookIds = <String>[].obs;                      // Max 10 recent books
  var bookOpenTimestamps = <String, int>{}.obs;            // bookId -> millisSinceEpoch
  var lastOpenedBookId = ''.obs;

  // Daily Learning Stats (for heatmap & analytics)
  var dailyVocabLearned = <String, int>{}.obs;             // 'yyyy-MM-dd' -> vocab count learned that day
  var dailyReviewCount = <String, int>{}.obs;              // 'yyyy-MM-dd' -> review count
  var dailyStudyMinutes = <String, int>{}.obs;             // 'yyyy-MM-dd' -> minutes spent studying

  // Streak & Overall Progress
  var currentStreak = 0.obs;                               // Current learning streak (consecutive days)
  var longestStreak = 0.obs;                               // Longest streak achieved
  var lastActiveDate = ''.obs;                             // 'yyyy-MM-dd' format
  var totalVocabLearned = 0.obs;                           // Total vocabulary learned (all time)
  var totalReviewCount = 0.obs;                            // Total reviews completed (all time)

  // Gamification (optional)
  var totalXP = 0.obs;
  var level = 1.obs;

  // Load config từ Hive hoặc dùng default
  Future<void> loadConfig() async {
    final box = await Hive.openBox(hiveBoxName);
    final config = box.get(hiveKey);

    if (config != null) {
      // Debug/General
      isDebugMode.value = config['isDebugMode'] ?? true;

      // API
      apiEndpoint.value = config['apiEndpoint'] ?? 'https://api.openai.com/v1';
      apiKey.value = config['apiKey'] ?? '';

      // GPT/LLM
      gptModel.value = config['gptModel'] ?? 'gpt-3.5-turbo';
      maxTokens.value = config['maxTokens'] ?? 150;
      temperature.value = config['temperature'] ?? 0.7;
      systemContext.value = config['systemContext'] ?? '';

      // TTS/Speech
      ttsEngine.value = config['ttsEngine'] ?? 'flutter_tts';
      speechRate.value = config['speechRate'] ?? 0.7;

      // Language/UI
      defaultLanguage.value = config['defaultLanguage'] ?? 'en-US';
      themeMode.value = config['themeMode'] ?? 'system';
      language.value = config['language'] ?? '';

      // Learning Data
      recentBookIds.value = List<String>.from(config['recentBookIds'] ?? []);
      bookOpenTimestamps.value = Map<String, int>.from(config['bookOpenTimestamps'] ?? {});
      lastOpenedBookId.value = config['lastOpenedBookId'] ?? '';
      dailyVocabLearned.value = Map<String, int>.from(config['dailyVocabLearned'] ?? {});
      dailyReviewCount.value = Map<String, int>.from(config['dailyReviewCount'] ?? {});
      dailyStudyMinutes.value = Map<String, int>.from(config['dailyStudyMinutes'] ?? {});
      currentStreak.value = config['currentStreak'] ?? 0;
      longestStreak.value = config['longestStreak'] ?? 0;
      lastActiveDate.value = config['lastActiveDate'] ?? '';
      totalVocabLearned.value = config['totalVocabLearned'] ?? 0;
      totalReviewCount.value = config['totalReviewCount'] ?? 0;
      totalXP.value = config['totalXP'] ?? 0;
      level.value = config['level'] ?? 1;
    } else {
      // Lấy theme và locale mặc định từ hệ thống
      themeMode.value = Get.isDarkMode ? 'dark' : 'light';
      language.value = Get.deviceLocale?.languageCode ?? 'en';
      enableWakewordBackground.value = false;
    }
  }

  // Lưu config vào Hive
  Future<void> saveConfig() async {
    final box = await Hive.openBox(hiveBoxName);
    await box.put(hiveKey, {
      // Debug/General
      'isDebugMode': isDebugMode.value,

      // API
      'apiEndpoint': apiEndpoint.value,
      'apiKey': apiKey.value,

      // GPT/LLM
      'gptModel': gptModel.value,
      'maxTokens': maxTokens.value,
      'temperature': temperature.value,
      'systemContext': systemContext.value,

      // TTS/Speech
      'ttsEngine': ttsEngine.value,
      'speechRate': speechRate.value,

      // Language/UI
      'defaultLanguage': defaultLanguage.value,
      'themeMode': themeMode.value,
      'language': language.value,

      // Wakeword
      'enableWakewordBackground': enableWakewordBackground.value,

      // Learning Data
      'recentBookIds': recentBookIds.toList(),
      'bookOpenTimestamps': Map<String, int>.from(bookOpenTimestamps),
      'lastOpenedBookId': lastOpenedBookId.value,
      'dailyVocabLearned': Map<String, int>.from(dailyVocabLearned),
      'dailyReviewCount': Map<String, int>.from(dailyReviewCount),
      'dailyStudyMinutes': Map<String, int>.from(dailyStudyMinutes),
      'currentStreak': currentStreak.value,
      'longestStreak': longestStreak.value,
      'lastActiveDate': lastActiveDate.value,
      'totalVocabLearned': totalVocabLearned.value,
      'totalReviewCount': totalReviewCount.value,
      'totalXP': totalXP.value,
      'level': level.value,
    });
  }

  // Khởi tạo controller và load config
  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  // ✅ Convert toàn bộ sang JSON để gửi qua isolate
  Map<String, dynamic> toJson() => {
        'isDebugMode': isDebugMode.value,
        'apiEndpoint': apiEndpoint.value,
        'apiKey': apiKey.value,
        'gptModel': gptModel.value,
        'maxTokens': maxTokens.value,
        'temperature': temperature.value,
        'systemContext': systemContext.value,
        'ttsEngine': ttsEngine.value,
        'speechRate': speechRate.value,
        'defaultLanguage': defaultLanguage.value,
        'themeMode': themeMode.value,
        'language': language.value,
        'enableWakewordBackground': enableWakewordBackground.value,
        // Learning data
        'recentBookIds': recentBookIds.toList(),
        'bookOpenTimestamps': Map<String, int>.from(bookOpenTimestamps),
        'lastOpenedBookId': lastOpenedBookId.value,
        'dailyVocabLearned': Map<String, int>.from(dailyVocabLearned),
        'dailyReviewCount': Map<String, int>.from(dailyReviewCount),
        'dailyStudyMinutes': Map<String, int>.from(dailyStudyMinutes),
        'currentStreak': currentStreak.value,
        'longestStreak': longestStreak.value,
        'lastActiveDate': lastActiveDate.value,
        'totalVocabLearned': totalVocabLearned.value,
        'totalReviewCount': totalReviewCount.value,
        'totalXP': totalXP.value,
        'level': level.value,
      };

  // ✅ Tạo lại controller từ JSON khi ở isolate
  static AppConfigController fromJson(Map<String, dynamic> json) {
    final c = AppConfigController();
    c._applyConfig(json);
    return c;
  }

  void _applyConfig(Map<String, dynamic> json) {
    isDebugMode.value = json['isDebugMode'] ?? true;
    apiEndpoint.value = json['apiEndpoint'] ?? 'https://api.openai.com/v1';
    apiKey.value = json['apiKey'] ?? '';
    gptModel.value = json['gptModel'] ?? 'gpt-3.5-turbo';
    maxTokens.value = json['maxTokens'] ?? 150;
    temperature.value = json['temperature'] ?? 0.7;
    systemContext.value = json['systemContext'] ?? '';
    ttsEngine.value = json['ttsEngine'] ?? 'flutter_tts';
    speechRate.value = json['speechRate'] ?? 0.9;
    defaultLanguage.value = json['defaultLanguage'] ?? 'en-US';
    themeMode.value = json['themeMode'] ?? 'system';
    language.value = json['language'] ?? '';
    enableWakewordBackground.value = json['enableWakewordBackground'] ?? false;
    // Learning data
    recentBookIds.value = List<String>.from(json['recentBookIds'] ?? []);
    bookOpenTimestamps.value = Map<String, int>.from(json['bookOpenTimestamps'] ?? {});
    lastOpenedBookId.value = json['lastOpenedBookId'] ?? '';
    dailyVocabLearned.value = Map<String, int>.from(json['dailyVocabLearned'] ?? {});
    dailyReviewCount.value = Map<String, int>.from(json['dailyReviewCount'] ?? {});
    dailyStudyMinutes.value = Map<String, int>.from(json['dailyStudyMinutes'] ?? {});
    currentStreak.value = json['currentStreak'] ?? 0;
    longestStreak.value = json['longestStreak'] ?? 0;
    lastActiveDate.value = json['lastActiveDate'] ?? '';
    totalVocabLearned.value = json['totalVocabLearned'] ?? 0;
    totalReviewCount.value = json['totalReviewCount'] ?? 0;
    totalXP.value = json['totalXP'] ?? 0;
    level.value = json['level'] ?? 1;
  }
}
