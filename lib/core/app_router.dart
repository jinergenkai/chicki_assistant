import 'package:chicki_buddy/ui/screens/assistant_settings_screen.dart';
import 'package:chicki_buddy/ui/screens/books_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/main_screen.dart';
import '../ui/screens/test_screen/sherpa_tts_test_screen.dart';

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  // navigatorKey: navigatorKey,
  routes: [
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
