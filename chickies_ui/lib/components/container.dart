import 'package:flutter/material.dart';

/// A container with rounded corners and shadow
class ChickiesContainer extends StatelessWidget {
  final Widget? child;
  final double? height;
  final double? width; 
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double borderRadius;
  final double elevation;

  const ChickiesContainer({
    super.key,
    this.child,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.color,
    this.borderRadius = 16,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      width: width,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: child,
    );
  }
}