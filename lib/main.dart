import 'dart:isolate';

import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/controllers/bubble_controller.dart';
import 'package:chicki_buddy/controllers/tts.controller.dart';
import 'package:chicki_buddy/core/app_lifecycle.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/models/voice_note.dart';
import 'package:chicki_buddy/services/wakeword/porcupine_wakeword_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:chicki_buddy/controllers/books_controller.dart';
import 'package:chicki_buddy/services/test_data_service.dart';
import 'package:chicki_buddy/services/unified_intent_handler_service.dart';
import 'package:chicki_buddy/services/data/book_data_service.dart';
import 'package:chicki_buddy/services/data/vocabulary_data_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(VocabularyAdapter());
  Hive.registerAdapter(BookAdapter());
  Hive.registerAdapter(BookSourceAdapter());

  // Hive.registerAdapter(VoiceNoteAdapter());
  // await Hive.openBox<VoiceNote>('voiceNoteBox');
  // await Hive.openBox<Vocabulary>('vocabularyBox');
  // await Hive.openBox<Book>('books');

  // Initialize Notifications
  // await NotificationService().initialize();

  // Inject AppConfigController and core services
  Get.put(AppConfigController(), permanent: true);
  // Get.put(PorcupineWakewordService(), permanent: true);
  
  // Data services MUST be initialized BEFORE controllers that depend on them
  await Get.putAsync(() async {
    final service = BookDataService();
    await service.onInit();
    return service;
  }, permanent: true);
  
  await Get.putAsync(() async {
    final service = VocabularyDataService();
    await service.onInit();
    return service;
  }, permanent: true);
  
  // Data access and intent handling (main isolate only)
  await Get.putAsync(() async {
    final service = UnifiedIntentHandlerService();
    await service.onInit();
    return service;
  }, permanent: true);
  
  // Controllers that depend on data services
  Get.put(VoiceController(), permanent: true);
  Get.put(BubbleController(), permanent: true);
  Get.put(BooksController(), permanent: true); // Global for voice commands
  
  // Test services
  // Get.put(TestDataService(), permanent: true); // Test offscreen data access

  FlutterForegroundTask.initCommunicationPort();

  // await VoiceIsolateManager().start();
  // await RiveNative.init();

  AppLifecycleHandler(
    onResumed: () {
      print("🟢 App resumed");
      // AppNavigator.instance.restoreStateIfNeeded();
    },
    onPaused: () {
      print("🔴 App paused");
    },
  );

  // traceBug();
  runApp(const MyApp());
}

void traceBug() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrintStack(label: 'STACK TRACE', stackTrace: details.stack);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          details.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  };
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
            textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
            extensions: <ThemeExtension<dynamic>>[
              MoonTheme(
                tokens: MoonTokens.light.copyWith(
                  colors: MoonTokens.light.colors.copyWith(
                    piccolo: const Color(0xFF90CAF9),
                  ),
                  typography: MoonTypography.typography.copyWith(
                    heading: MoonTypography.typography.heading.apply(
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                      fontWeightDelta: -1,
                      fontVariations: [const FontVariation('wght', 500)],
                    ),
                    body: MoonTypography.typography.body.apply(
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                ),
              ),
            ],
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF1F1F1F),
            textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
            extensions: <ThemeExtension<dynamic>>[
              MoonTheme(
                tokens: MoonTokens.dark.copyWith(
                  colors: mdsDarkColors,
                  typography: MoonTypography.typography.copyWith(
                    heading: MoonTypography.typography.heading.apply(
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                      fontWeightDelta: -1,
                      fontVariations: [const FontVariation('wght', 500)],
                    ),
                    body: MoonTypography.typography.body.apply(
                      fontFamily: GoogleFonts.dmSans().fontFamily,
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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
        ));
  }
}
