import 'package:flutter/material.dart';

class AppLifecycleHandler with WidgetsBindingObserver {
  final VoidCallback onResumed;
  final VoidCallback onPaused;

  AppLifecycleHandler({required this.onResumed, required this.onPaused}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.paused:
        onPaused();
        break;
      default:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}