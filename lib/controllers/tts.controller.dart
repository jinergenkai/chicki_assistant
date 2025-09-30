import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/sherpa_tts_service.dart';
import 'app_config.controller.dart';

class TTSController extends GetxController {
  // Singleton instances của services
  static final TextToSpeechService _flutterTTSInstance = TextToSpeechService();
  static final SherpaTTSService _sherpaTTSInstance = SherpaTTSService();
  
  late TTSService _currentService;
  final _config = Get.find<AppConfigController>();
  var isInitialized = false.obs;

  TTSService get service => _currentService;

  @override
  void onInit() {
    super.onInit();
    _initCurrentService();

    // Listen to changes in ttsEngine config
    ever(_config.ttsEngine, (value) async {
      // final result = await Get.dialog(
      //   AlertDialog(
      //     title: const Text('Thay đổi Text-to-Speech Engine'),
      //     content: const Text('Bạn có chắc muốn thay đổi TTS engine không? Điều này sẽ dừng âm thanh đang phát.'),
      //     actions: [
      //       TextButton(
      //         child: const Text('Hủy'),
      //         onPressed: () => Get.back(result: false),
      //       ),
      //       TextButton(
      //         child: const Text('Đồng ý'),
      //         onPressed: () => Get.back(result: true),
      //       ),
      //     ],
      //   ),
      // );

      // if (result == true) {
        await _switchService();
      // } else {
      //   // Revert the change if user cancels
      //   _config.ttsEngine.value = _config.ttsEngine.value == 'sherpa' ? 'flutter_tts' : 'sherpa';
      // }
    });
  }

  Future<void> _initCurrentService() async {
    try {
      _currentService = _getServiceInstance();
      if (!_currentService.isSpeaking) {
        await _currentService.initialize();
      }
      isInitialized.value = true;
    } catch (e) {
      isInitialized.value = false;
      rethrow;
    }
  }

  Future<void> _switchService() async {
    try {
      // Stop current service if speaking
      if (_currentService.isSpeaking) {
        await _currentService.stop();
      }

      // Switch to new service
      _currentService = _getServiceInstance();
      
      // Initialize if needed
      if (!_currentService.isSpeaking) {
        await _currentService.initialize();
      }
      
      isInitialized.value = true;
      Get.snackbar(
        'Thành công',
        'Đã chuyển sang ${_config.ttsEngine.value == 'sherpa' ? 'Sherpa TTS' : 'Flutter TTS'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isInitialized.value = false;
      Get.snackbar(
        'Lỗi',
        'Không thể chuyển TTS engine: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  TTSService _getServiceInstance() {
    return _config.ttsEngine.value == 'sherpa' 
        ? _sherpaTTSInstance 
        : _flutterTTSInstance;
  }

  Future<void> speak(String text) async {
    if (!isInitialized.value) {
      throw Exception('TTS service not initialized');
    }
    await _currentService.speak(text);
  }

  Future<void> stop() async {
    if (!isInitialized.value) return;
    await _currentService.stop();
  }

  Future<void> setLanguage(String language) async {
    if (!isInitialized.value) return;
    await _currentService.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    if (!isInitialized.value) return;
    await _currentService.setSpeechRate(rate);
  }

  bool get isSpeaking => _currentService.isSpeaking;

  @override
  void onClose() {
    if (_currentService.isSpeaking) {
      _currentService.stop();
    }
    super.onClose();
  }
}