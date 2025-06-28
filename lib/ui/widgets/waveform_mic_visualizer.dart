import 'package:flutter/material.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

class WaveformMicVisualizer extends StatelessWidget {
  final Stream<double> rmsStream;
  final Color? color;
  final double height;

  const WaveformMicVisualizer({
    super.key,
    required this.rmsStream,
    this.color,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AnimatedWaveList(
        stream: rmsStream.map((rms) {
          // Chuẩn hóa rms về 0-1, scale lên 100 cho Amplitude
          final norm = ((rms - (-2.0)) / (10.0 - (-2.0))).clamp(0.0, 1.0);
          return Amplitude(current: (norm * 100), max: 100);
        }),
      ),
    );
  }
}