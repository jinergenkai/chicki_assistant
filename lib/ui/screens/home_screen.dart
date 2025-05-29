import 'package:flutter/material.dart';
import 'package:chickies_ui/chickies_ui.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChickiesAppBar(
        title: 'Chickies Assistant',
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: onThemeToggle,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: const ChatScreen(),
    );
  }
}