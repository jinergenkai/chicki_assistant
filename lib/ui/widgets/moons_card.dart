import 'package:flutter/material.dart';

class MoonsCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? width;

  const MoonsCard({
    super.key,
    required this.child,
    this.borderRadius = 25,
    this.padding,
    this.margin = const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9AA7B2).withOpacity(0.10),
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: child,
    );
  }
}

