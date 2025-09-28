import 'package:flutter/material.dart';

enum SuperActionType {
  createVocabulary,
  createVoiceNote,
  runDeviceCommand,
  runCustomCode,
}

class SuperAction {
  final String id; // unique
  final String title;
  final IconData icon;
  final Color color;
  final SuperActionType type;
  final Future<void> Function()? action; // callback chạy khi nhấn

  SuperAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    this.action,
  });
}
