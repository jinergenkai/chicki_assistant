import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/main_screen.dart';
import '../ui/screens/test_screen/sherpa_tts_test_screen.dart';

final GoRouter appRouter = GoRouter(
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