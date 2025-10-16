import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

class SeededRandom {
  int _state;
  SeededRandom(this._state);
  
  double nextDouble() {
    _state = (_state * 1664525 + 1013904223) & 0xffffffff;
    return (_state / 0xffffffff);
  }

  int nextInt(int max) => (nextDouble() * max).floor();
}

List<Color> generateHarmonicColors(SeededRandom rng, int count) {
  final hue = rng.nextDouble() * 360; // base hue
  final harmonyOffsets = [0, 10, -10, 30, -30]; // analog-like
  List<Color> colors = [];
  for (int i = 0; i < count; i++) {
    final h = (hue + harmonyOffsets[rng.nextInt(harmonyOffsets.length)]) % 360;
    final s = 0.5 + rng.nextDouble() * 0.4; // saturation 0.5–0.9
    final l = 0.3 + rng.nextDouble() * 0.3; // lightness 0.4–0.7
    colors.add(HSLColor.fromAHSL(1.0, h, s, l).toColor());
  }
  return colors;
}

List<Offset> generatePoints(SeededRandom rng, int count) {
  return List.generate(count, (_) => Offset(
    0.1 + rng.nextDouble() * 0.8, // avoid edges
    0.1 + rng.nextDouble() * 0.8,
  ));
}



int stringHash(String input, [String salt = ""]) {
  const int fnvPrime = 16777619;
  int hash = 2166136261;
  for (int i = 0; i < (input + salt).length; i++) {
    hash ^= (input + salt).codeUnitAt(i);
    hash *= fnvPrime;
  }
  return hash & 0x7fffffff; // positive
}

MeshGradient RandomGradient(String id, {String seed = "default", Widget? child}) {
  final hash = stringHash(id, seed);
  final rng = SeededRandom(hash);
  final count = 3 + rng.nextInt(3); // 3–5 points
  final colors = generateHarmonicColors(rng, count);
  final points = generatePoints(rng, count);

  return MeshGradient(
    points: List.generate(count, (i) => MeshGradientPoint(
      position: points[i],
      color: colors[i],
    )),
    options: MeshGradientOptions(),
    child: child ?? Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    ),
  );
}
