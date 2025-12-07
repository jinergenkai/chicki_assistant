import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String audioPath)? onRecordingComplete;

  const VoiceRecorderWidget({super.key, this.onRecordingComplete});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recorderInitialized = false;
  String? _recordedFilePath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      await _recorder.openRecorder();
      setState(() => _recorderInitialized = true);
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/voice_$timestamp.m4a';

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacMP4,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
        _recordedFilePath = filePath;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      _recordTimer?.cancel();

      setState(() {
        _isRecording = false;
      });

      if (_recordedFilePath != null && widget.onRecordingComplete != null) {
        widget.onRecordingComplete!(_recordedFilePath!);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) return;

    try {
      if (_isPlaying) {
        await _player.stop();
        setState(() => _isPlaying = false);
      } else {
        await _player.play(DeviceFileSource(_recordedFilePath!));
        setState(() => _isPlaying = true);

        _player.onPlayerComplete.listen((_) {
          setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      print('Error playing recording: $e');
    }
  }

  void _deleteRecording() {
    try {
      if (_recordedFilePath != null) {
        File(_recordedFilePath!).deleteSync();
      }
      setState(() {
        _recordedFilePath = null;
        _recordDuration = Duration.zero;
      });
    } catch (e) {
      print('Error deleting recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Microphone icon with animation
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red.shade50 : Colors.blue.shade50,
              border: Border.all(
                color: _isRecording ? Colors.red.shade400 : Colors.blue.shade400,
                width: _isRecording ? 3 : 2,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none_rounded,
              size: 48,
              color: _isRecording ? Colors.red.shade600 : Colors.blue.shade600,
            ),
          ),

          const SizedBox(height: 20),

          // Duration
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _isRecording ? Colors.red.shade600 : Colors.grey.shade900,
            ),
          ),

          const SizedBox(height: 24),

          // Control buttons
          if (!_isRecording && _recordedFilePath == null)
            // Start recording
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.fiber_manual_record),
              label: const Text('Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          else if (_isRecording)
            // Stop recording
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          else
            // Play/delete recorded audio
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _playRecording,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Stop' : 'Play'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
