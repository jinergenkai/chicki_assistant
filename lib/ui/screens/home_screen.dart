import 'package:flutter/material.dart';
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
      extendBody: true,
      appBar: AppBar(
        title: const Text('Chickies Assistant'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: onThemeToggle,
            tooltip: 'Toggle theme',
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: const ChatScreen(),
    );
  }
}