import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/ui/screens/assistant_settings_screen.dart';
import 'package:chicki_buddy/ui/screens/books_screen.dart';
import 'package:chicki_buddy/ui/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/main_screen.dart';
import '../ui/screens/test_screen/sherpa_tts_test_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  redirect: (context, state) {
    final appConfig = Get.find<AppConfigController>();
    final isOnboarding = state.matchedLocation == '/onboarding';
    
    // If first time user and not on onboarding, redirect to onboarding
    if (appConfig.isFirstTimeUser.value && !isOnboarding) {
      return '/onboarding';
    }
    
    // If not first time and on onboarding, redirect to home
    if (!appConfig.isFirstTimeUser.value && isOnboarding) {
      return '/';
    }
    
    return null; // No redirect needed
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => const MainScreen(),
      routes: [
        GoRoute(
          path: '/',
          name: 'chat',
          builder: (context, state) => const ChatScreen(),
        ),
                GoRoute(
          path: '/books',
          name: 'books',
          builder: (context, state) => const BooksScreen(),
        ),
                GoRoute(
          path: '/assistant-settings',
          name: 'assistantSettings',
          builder: (context, state) => const AssistantSettingsScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/sherpa-tts-test',
          name: 'sherpa-tts-test',
          builder: (context, state) => const SherpaTtsTestScreen(),
        ),
      ],
    ),
  ],
);
