import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/birthday_list_screen.dart';
import '../ui/screens/birthday_calendar_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/gift_suggestions_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/main_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const BirthdayCalendarScreen(),
        ),
        GoRoute(
          path: '/birthdays',
          name: 'birthdays',
          builder: (context, state) => const BirthdayListScreen(),
        ),
        GoRoute(
          path: '/gifts',
          name: 'gifts',
          builder: (context, state) => const GiftSuggestionsScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);