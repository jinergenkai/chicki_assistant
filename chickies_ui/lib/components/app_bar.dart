import 'package:flutter/material.dart';

/// A customizable app bar component for Chickies UI
class ChickiesAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display in the app bar
  final String? title;
  
  /// A widget to display before the title
  final Widget? leading;
  
  /// A list of widgets to display after the title
  final List<Widget>? actions;
  
  /// The background color of the app bar
  final Color? backgroundColor;
  
  /// The color of text and icons in the app bar
  final Color? foregroundColor;
  
  /// The elevation of the app bar
  final double? elevation;
  
  /// Whether to center the title
  final bool centerTitle;
  
  /// Optional widget to display below the app bar
  final PreferredSizeWidget? bottom;

  const ChickiesAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
}