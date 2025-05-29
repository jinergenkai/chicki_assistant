import 'package:flutter/material.dart';
import 'color_scheme.dart';

/// Typography configuration for Chickies UI
class ChickiesTypography {
  const ChickiesTypography({this.fontFamily = 'MadimiOne'});
  
  final String fontFamily;

  TextTheme get textTheme => TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w400,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// Theme configuration for Chickies UI
class ChickiesTheme {
  /// Spacing scale for the theme
  static const spacing = ChickiesSpacing();

  /// Default light theme
  static ThemeData light({
    ChickiesColorScheme? colors,
    String? fontFamily,
  }) {
    final colorScheme = (colors ?? ChickiesColorScheme.light).toColorScheme();
    final defaultFontFamily = fontFamily ?? 'MadimiOne';
    
    final typography = ChickiesTypography(fontFamily: defaultFontFamily);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      textTheme: typography.textTheme,
    );
  }

  /// Default dark theme
  static ThemeData dark({
    ChickiesColorScheme? colors,
    String? fontFamily,
  }) {
    final colorScheme = (colors ?? ChickiesColorScheme.dark).toColorScheme(brightness: Brightness.dark);
    return light(
      colors: colors ?? ChickiesColorScheme.dark,
      fontFamily: fontFamily,
    ).copyWith(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}

/// Spacing scale configuration
class ChickiesSpacing {
  const ChickiesSpacing();

  final double xxxs = 2;
  final double xxs = 4;
  final double xs = 8;
  final double sm = 12;
  final double md = 16;
  final double lg = 24;
  final double xl = 32;
  final double xxl = 40;
  final double xxxl = 48;

  /// Default padding scale
  EdgeInsets get padding => const EdgeInsets.all(16);
  
  /// Default margin scale  
  EdgeInsets get margin => const EdgeInsets.all(8);

  /// Default border radius
  double get borderRadius => 16;
}
