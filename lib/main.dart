import 'dart:isolate';

import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/controllers/bubble_controller.dart';
import 'package:chicki_buddy/controllers/tts.controller.dart';
import 'package:chicki_buddy/core/app_lifecycle.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/models/voice_note.dart';
import 'package:chicki_buddy/services/wakeword/porcupine_wakeword_service.dart';
import 'package:chicki_buddy/voice/core/voice_isolate_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/services/notification_service.dart';
import 'package:chicki_buddy/ui/screens/main_screen.dart';
import 'package:chicki_buddy/core/app_router.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/controllers/chat_controller.dart';
import 'package:chicki_buddy/controllers/voice_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(VocabularyAdapter());
  Hive.registerAdapter(VoiceNoteAdapter());
  Hive.registerAdapter(BookAdapter());

  await Hive.openBox<VoiceNote>('voiceNoteBox');
  await Hive.openBox<Vocabulary>('vocabularyBox');
  await Hive.openBox<Book>('books');

  // Initialize Notifications
  // await NotificationService().initialize();

  // Inject AppConfigController
  Get.put(AppConfigController(), permanent: true);
  Get.put(PorcupineWakewordService(), permanent: true);
  Get.put(VoiceController(), permanent: true);
  Get.put(BubbleController(), permanent: true);

  FlutterForegroundTask.initCommunicationPort();

  await VoiceIsolateManager().start();

  AppLifecycleHandler(
    onResumed: () {
      print("🟢 App resumed");
      // AppNavigator.instance.restoreStateIfNeeded();
    },
    onPaused: () { print("🔴 App paused"); },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<AppConfigController>();
    return Obx(() => GetMaterialApp.router(
          title: 'Chicky Buddy',
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF6F7F9),
            primaryColor: const Color(0xFF90CAF9),
            colorScheme: ThemeData.light().colorScheme.copyWith(
                  primary: const Color(0xFF90CAF9),
                ),
            textTheme: ThemeData.light().textTheme.apply(fontFamily: 'DMSans'),
            extensions: <ThemeExtension<dynamic>>[
              MoonTheme(
                tokens: MoonTokens.light.copyWith(
                  colors: MoonTokens.light.colors.copyWith(
                    piccolo: const Color(0xFF90CAF9),
                  ),
                  typography: MoonTypography.typography.copyWith(
                    heading: MoonTypography.typography.heading.apply(
                      fontFamily: "DMSans",
                      fontWeightDelta: -1,
                      fontVariations: [const FontVariation('wght', 500)],
                    ),
                    body: MoonTypography.typography.body.apply(
                      fontFamily: "DMSans",
                    ),
                  ),
                ),
              ),
            ],
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF1F1F1F),
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'DMSans'),
            extensions: <ThemeExtension<dynamic>>[
              MoonTheme(
                tokens: MoonTokens.dark.copyWith(
                  colors: mdsDarkColors,
                  typography: MoonTypography.typography.copyWith(
                    heading: MoonTypography.typography.heading.apply(
                      fontFamily: "DMSans",
                      fontWeightDelta: -1,
                      fontVariations: [const FontVariation('wght', 500)],
                    ),
                    body: MoonTypography.typography.body.apply(
                      fontFamily: "DMSans",
                    ),
                  ),
                ),
              ),
            ],
          ),
          themeMode: appConfig.themeMode.value == 'dark'
              ? ThemeMode.dark
              : appConfig.themeMode.value == 'light'
                  ? ThemeMode.light
                  : ThemeMode.system,
          routerDelegate: appRouter.routerDelegate,
          routeInformationParser: appRouter.routeInformationParser,
          routeInformationProvider: appRouter.routeInformationProvider,
          debugShowCheckedModeBanner: false,
          locale: Locale(appConfig.language.value.isNotEmpty ? appConfig.language.value : 'en'),
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
        ));
  }
}
