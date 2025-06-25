import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/models/friend.dart';
import 'package:chicki_buddy/services/notification_service.dart';
import 'package:chicki_buddy/ui/screens/main_screen.dart';
import 'package:chicki_buddy/core/app_router.dart';

void main() async {
// Định nghĩa custom colors cho Moon Design (có thể chỉnh sửa theo ý bạn)
  final mdsLightColors = MoonTokens.light.colors;
  final mdsDarkColors = MoonTokens.dark.colors;
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(FriendAdapter());
  await Hive.openBox<Friend>('friends');

  // Initialize Notifications
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Birthday App',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        extensions: <ThemeExtension<dynamic>>[
          MoonTheme(
            tokens: MoonTokens.light.copyWith(
              colors: mdsLightColors,
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
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
