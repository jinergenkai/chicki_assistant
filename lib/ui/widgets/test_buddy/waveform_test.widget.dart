import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:chicki_buddy/ui/widgets/waveform_mic_visualizer.dart';

class WaveformTestWidget extends StatefulWidget {
  const WaveformTestWidget({super.key});

  @override
  State<WaveformTestWidget> createState() => _WaveformTestWidgetState();
}

class _WaveformTestWidgetState extends State<WaveformTestWidget> {
  bool _isRecording = false;
  Timer? _timer;
  final _controller = StreamController<double>();

  void _startSimulation() {
    const duration = Duration(milliseconds: 100);
    _timer = Timer.periodic(duration, (timer) {
      // Tạo giá trị RMS ngẫu nhiên từ -2 đến 10
      final random = Random();
      final rms = -2.0 + random.nextDouble() * 12.0;
      _controller.add(rms);
    });
  }

  void _stopSimulation() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopSimulation();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test hiển thị cường độ âm thanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 100,
                child: WaveformMicVisualizer(
                  rmsStream: _controller.stream,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: MoonButton(
                onTap: () {
                  setState(() {
                    _isRecording = !_isRecording;
                    if (_isRecording) {
                      _startSimulation();
                    } else {
                      _stopSimulation();
                    }
                  });
                },
                backgroundColor: _isRecording 
                  ? context.moonColors!.gohan 
                  : context.moonColors!.piccolo,
                label: Text(_isRecording ? 'Dừng' : 'Bắt đầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}