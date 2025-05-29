import 'package:flutter/material.dart';

/// The color configuration for Chickies UI themes
class ChickiesColorScheme {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color text;
  final Color accent;
  final Color shadow;

  const ChickiesColorScheme({
    this.primary = const Color(0xFF7e7dd6),
    this.secondary = const Color(0xFFeef2f9),
    this.background = const Color(0xFFeef2f9),
    this.surface = const Color(0xFFFFFFFF), 
    this.text = const Color(0xFF000000),
    this.accent = const Color(0xFFc65158),
    this.shadow = const Color(0xFFd3ddee),
  });

  /// Creates a copy of this color scheme with the given fields replaced with new values
  ChickiesColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? text,
    Color? accent,
    Color? shadow,
  }) {
    return ChickiesColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      shadow: shadow ?? this.shadow,
    );
  }

  /// Creates a dark variant of this color scheme
  ChickiesColorScheme toDark() {
    return copyWith(
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      text: const Color(0xFFFFFFFF),
      shadow: const Color(0xFF2C2C2C),
    );
  }

  /// Converts this color scheme to Flutter's ColorScheme
  ColorScheme toColorScheme({Brightness brightness = Brightness.light}) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
      secondary: secondary,
      onSecondary: brightness == Brightness.light ? Colors.black : Colors.white,
      surface: surface,
      onSurface: text,
      error: accent,
      onError: Colors.white,
    );
  }

  /// Default light color scheme
  static const light = ChickiesColorScheme();

  /// Default dark color scheme  
  static final dark = const ChickiesColorScheme().toDark();
}