import 'package:get/get.dart';
import 'package:hive/hive.dart';

class AppConfigController extends GetxController {
  static const String hiveBoxName = 'app_config';
  static const String hiveKey = 'config';

  // Các thuộc tính cấu hình
  var isDebugMode = true.obs;
  var apiEndpoint = 'https://api.openai.com/v1'.obs;
  var speechRate = 0.9.obs;
  var defaultLanguage = 'en-US'.obs;
  var gptModel = 'gpt-3.5-turbo'.obs;
  var maxTokens = 150.obs;
  var temperature = 0.7.obs;

  // Theme: 'system', 'dark', 'light'
  var themeMode = 'system'.obs;
  // Language code, ví dụ: 'vi-VN', 'en-US'
  var language = ''.obs;

  // Enable wakeword background/foreground service (Android)
  var enableWakewordBackground = false.obs;

  // Load config từ Hive hoặc dùng default
  Future<void> loadConfig() async {
    final box = await Hive.openBox(hiveBoxName);
    final config = box.get(hiveKey);

    if (config != null) {
      isDebugMode.value = config['isDebugMode'] ?? true;
      apiEndpoint.value = config['apiEndpoint'] ?? 'https://api.openai.com/v1';
      speechRate.value = config['speechRate'] ?? 0.7;
      defaultLanguage.value = config['defaultLanguage'] ?? 'en-US';
      gptModel.value = config['gptModel'] ?? 'gpt-3.5-turbo';
      maxTokens.value = config['maxTokens'] ?? 150;
      temperature.value = config['temperature'] ?? 0.7;
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
      'isDebugMode': isDebugMode.value,
      'apiEndpoint': apiEndpoint.value,
      'speechRate': speechRate.value,
      'defaultLanguage': defaultLanguage.value,
      'gptModel': gptModel.value,
      'maxTokens': maxTokens.value,
      'temperature': temperature.value,
      'themeMode': themeMode.value,
      'language': language.value,
      'enableWakewordBackground': enableWakewordBackground.value,
    });
  }

  // Khởi tạo controller và load config
  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }
}