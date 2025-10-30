import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlashCardSwipeOverlay extends StatelessWidget {
  final double swipeProgress; // -1.0 to 1.0
  final double cardWidth;

  const FlashCardSwipeOverlay({
    super.key,
    required this.swipeProgress,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final absProgress = swipeProgress.abs();
    final opacity = (absProgress * 2).clamp(0.0, 0.9);
    final isRight = swipeProgress > 0;

    if (absProgress < 0.05) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(48),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isRight ? Alignment.centerLeft : Alignment.centerRight,
                end: isRight ? Alignment.centerRight : Alignment.centerLeft,
                colors: isRight
                    ? [
                        Colors.green.withOpacity(opacity * 0.3),
                        Colors.green.withOpacity(opacity * 0.1),
                      ]
                    : [
                        Colors.red.withOpacity(opacity * 0.3),
                        Colors.red.withOpacity(opacity * 0.1),
                      ],
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.5 + (absProgress * 0.5),
                child: Transform.rotate(
                  angle: isRight ? -0.2 : 0.2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: (isRight ? Colors.green : Colors.red).withOpacity(opacity),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isRight ? Colors.green : Colors.red).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRight ? Icons.check_circle : Icons.cancel,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRight ? 'ĐÃ BIẾT' : 'CẦN ÔN',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
