# Chickies UI Theme System

The theme system provides consistent styling across Chickies UI components.

## Usage

### Basic Usage

```dart
import 'package:chickies_ui/chickies_ui.dart';

void main() {
  runApp(
    MaterialApp(
      theme: defaultTheme, // Use default light theme
      darkTheme: darkTheme, // Use default dark theme
      // ...
    ),
  );
}
```

### Custom Colors

```dart
final customColors = ChickiesColorScheme(
  primary: Color(0xFF6200EE),
  secondary: Color(0xFF03DAC6),
  background: Color(0xFFF5F5F5),
  surface: Colors.white,
  text: Colors.black87,
  accent: Color(0xFFFF4081),
);

MaterialApp(
  theme: ChickiesTheme.light(colors: customColors),
  darkTheme: ChickiesTheme.dark(colors: customColors),
)
```

### Spacing

Access consistent spacing values through `ChickiesTheme.spacing`:

```dart
final padding = ChickiesTheme.spacing.md;  // 16.0
final margin = ChickiesTheme.spacing.sm;   // 12.0
final radius = ChickiesTheme.spacing.borderRadius; // 16.0

// Available scales:
// xxxs (2.0), xxs (4.0), xs (8.0), sm (12.0)
// md (16.0), lg (24.0), xl (32.0), xxl (40.0), xxxl (48.0)
```

## Theme Properties

The theme system includes:

- Color scheme management
- Typography scales
- Component-specific themes
- Spacing system
- Light/dark variants

## Components

All Chickies UI components automatically use the theme. Example with AppBar:

```dart
ChickiesAppBar(
  title: 'My App',
  // Optional overrides:
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
)