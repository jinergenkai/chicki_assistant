import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';

import '../../../services/sherpa-onnx/index.dart';
import '../../../core/logger.dart';

class SherpaTtsTestController extends GetxController {
  final textController = TextEditingController(text: 'Hello, this is Sherpa-ONNX TTS test.');
  final speedController = TextEditingController(text: '1.0');

  final RxBool isInitialized = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxString statusMessage = 'Not initialized'.obs;
  final RxDouble speechSpeed = 1.0.obs;

  late final SherpaTtsService _ttsService;
  late final SherpaIsolateTtsService _isolateTtsService;
  final RxBool useIsolateService = false.obs;

  @override
  void onInit() {
    super.onInit();
    _ttsService = SherpaTtsService();
    _isolateTtsService = SherpaIsolateTtsService();

    speedController.addListener(() {
      final speed = double.tryParse(speedController.text) ?? 1.0;
      speechSpeed.value = speed.clamp(0.5, 3.0);
    });
  }

  Future<void> initialize() async {
    try {
      statusMessage.value = 'Initializing...';

      if (useIsolateService.value) {
        await _isolateTtsService.initialize();
      } else {
        await _ttsService.initialize();
      }

      isInitialized.value = true;
      statusMessage.value = 'Initialized successfully';
      logger.info('Sherpa TTS initialized');
    } catch (e) {
      isInitialized.value = false;
      statusMessage.value = 'Initialization failed: $e';
      logger.error('Sherpa TTS initialization failed: $e');
    }
  }

  Future<void> speak() async {
    if (!isInitialized.value) {
      statusMessage.value = 'Please initialize first';
      return;
    }

    final text = textController.text.trim();
    if (text.isEmpty) {
      statusMessage.value = 'Please enter text to speak';
      return;
    }

    try {
      isSpeaking.value = true;
      statusMessage.value = 'Speaking...';

      final service = useIsolateService.value ? _isolateTtsService : _ttsService;

      // Set speech rate before speaking
      await service.setSpeechRate(speechSpeed.value);

      await service.speak(text);

      statusMessage.value = 'Speech completed';
    } catch (e) {
      statusMessage.value = 'Speech failed: $e';
      logger.error('Sherpa TTS speech failed: $e');
    } finally {
      isSpeaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      final service = useIsolateService.value ? _isolateTtsService : _ttsService;
      await service.stop();
      isSpeaking.value = false;
      statusMessage.value = 'Stopped';
    } catch (e) {
      statusMessage.value = 'Stop failed: $e';
      logger.error('Sherpa TTS stop failed: $e');
    }
  }

  Future<void> playLast() async {
    if (useIsolateService.value) {
      statusMessage.value = 'Play last not supported in isolate mode';
      return;
    }

    try {
      await _ttsService.playLast();
      statusMessage.value = 'Playing last audio';
    } catch (e) {
      statusMessage.value = 'Play last failed: $e';
      logger.error('Play last failed: $e');
    }
  }

  void toggleService() {
    useIsolateService.value = !useIsolateService.value;
    isInitialized.value = false;
    statusMessage.value = 'Switched to ${useIsolateService.value ? 'Isolate' : 'Regular'} service. Please initialize.';
  }

  @override
  void onClose() {
    textController.dispose();
    speedController.dispose();
    _ttsService.dispose();
    _isolateTtsService.dispose();
    super.onClose();
  }
}

class SherpaTtsTestScreen extends StatelessWidget {
  const SherpaTtsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SherpaTtsTestController());

    return Scaffold(
      backgroundColor: context.moonColors?.gohan,
      appBar: AppBar(
        title: Text(
          'Sherpa-ONNX TTS Test',
          style: TextStyle(color: context.moonColors?.bulma),
        ),
        backgroundColor: context.moonColors?.goku,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Selection
            Card(
              color: context.moonColors?.goku,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TTS Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.moonColors?.bulma,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: MoonSwitch(
                                value: controller.useIsolateService.value,
                                onChanged: (value) => controller.toggleService(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.useIsolateService.value ? 'Isolate Service' : 'Regular Service',
                              style: TextStyle(color: context.moonColors?.bulma),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Card(
              color: context.moonColors?.goku,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.moonColors?.bulma,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          controller.statusMessage.value,
                          style: TextStyle(
                            color: controller.isInitialized.value ? context.moonColors?.krillin : context.moonColors?.chichi,
                          ),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Speech Speed Control
            Card(
              color: context.moonColors?.goku,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speech Speed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.moonColors?.bulma,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Column(
                          children: [
                            Slider(
                              value: controller.speechSpeed.value,
                              min: 0.5,
                              max: 3.0,
                              divisions: 25,
                              label: controller.speechSpeed.value.toStringAsFixed(2),
                              onChanged: (value) {
                                controller.speechSpeed.value = value;
                                controller.speedController.text = value.toStringAsFixed(2);
                              },
                            ),
                            Text(
                              'Speed: ${controller.speechSpeed.value.toStringAsFixed(2)}x',
                              style: TextStyle(color: context.moonColors?.bulma),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Text Input
            Card(
              color: context.moonColors?.goku,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text to Speak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.moonColors?.bulma,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MoonTextInput(
                      controller: controller.textController,
                      hintText: 'Enter text to convert to speech...',
                      maxLines: 3,
                      textInputSize: MoonTextInputSize.lg,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Obx(() => MoonFilledButton(
                      onTap: controller.isInitialized.value ? null : controller.initialize,
                      label: const Text('Initialize'),
                      buttonSize: MoonButtonSize.lg,
                    )),
                Obx(() => MoonFilledButton(
                      onTap: (controller.isInitialized.value && !controller.isSpeaking.value) ? controller.speak : null,
                      label: const Text('Speak'),
                      buttonSize: MoonButtonSize.lg,
                    )),
                Obx(() => MoonOutlinedButton(
                      onTap: controller.isSpeaking.value ? controller.stop : null,
                      label: const Text('Stop'),
                      buttonSize: MoonButtonSize.lg,
                    )),
                Obx(() => MoonOutlinedButton(
                      onTap: (controller.isInitialized.value && !controller.useIsolateService.value) ? controller.playLast : null,
                      label: const Text('Play Last'),
                      buttonSize: MoonButtonSize.lg,
                    )),
              ],
            ),

            const SizedBox(height: 16),

                    const SizedBox(height: 500),
          ],
        ),
      ),
    );
  }
}
