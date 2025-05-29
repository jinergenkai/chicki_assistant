import 'package:flutter/material.dart';

class ChickiesIconButton extends StatelessWidget {
  /// Called when button is pressed
  final VoidCallback onPressed;
  
  /// Icon to display
  final IconData icon;

  /// Size of the icon and button
  final double size;

  /// Icon color 
  final Color? iconColor;
  
  /// Background color
  final Color? backgroundColor;
  
  /// Whether to show a shadow
  final bool showShadow;

  const ChickiesIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 24.0,
    this.iconColor,
    this.backgroundColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      icon: Icon(
        icon,
        size: size,
        color: iconColor ?? theme.colorScheme.onPrimary,
      ),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        minimumSize: Size(size * 2, size * 2),
        shape: const CircleBorder(),
        elevation: showShadow ? 2 : 0,
        shadowColor: showShadow ? theme.colorScheme.shadow.withOpacity(0.2) : null,
      ),
      onPressed: onPressed,
    );
  }
}