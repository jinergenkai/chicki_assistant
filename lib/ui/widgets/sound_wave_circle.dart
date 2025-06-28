import 'package:flutter/material.dart';

class SoundWaveCircle extends StatelessWidget {
  final double rmsDB;
  final double minRadius;
  final double maxRadius;
  final Color? color;

  const SoundWaveCircle({
    super.key,
    required this.rmsDB,
    this.minRadius = 32,
    this.maxRadius = 64,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // SpeechToText trả rmsDB từ -2.0 đến 10.0 (hoặc 0-10)
    // Chuyển về tỉ lệ 0-1, clamp lại cho an toàn
    final normalized = ((rmsDB - (-2.0)) / (10.0 - (-2.0))).clamp(0.0, 1.0);
    final radius = minRadius + (maxRadius - minRadius) * normalized;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color ?? Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.mic,
            color: color ?? Theme.of(context).colorScheme.primary,
            size: minRadius,
          ),
        ),
      ),
    );
  }
}