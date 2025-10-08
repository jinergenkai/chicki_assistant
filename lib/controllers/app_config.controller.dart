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
  }
}
