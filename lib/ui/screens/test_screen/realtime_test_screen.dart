import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:openai_realtime_dart/openai_realtime_dart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart' hide Codec;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class RealtimeTestScreen extends StatefulWidget {
  const RealtimeTestScreen({super.key});

  @override
  State<RealtimeTestScreen> createState() => _RealtimeTestScreenState();
}

class _RealtimeTestScreenState extends State<RealtimeTestScreen> {
  late RealtimeClient client;
  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  int _audioCounter = 0;
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  final TextEditingController textController = TextEditingController();
  bool connected = false;
  bool _isPlaying = false;
  final List<Uint8List> _audioChunks = [];
  Timer? _playbackTimer;
  bool _isCollectingChunks = false;
  String? _lastRecordingPath;
  String _microphoneInfo = 'Unknown';
  List<String> _availableMicrophones = [];
  String? _selectedMicrophone;

  @override
  void initState() {
    super.initState();
    _loadMicrophoneInfo();
    _initRecorder();
    initRealtimeClient();
  }

  Future<void> _loadMicrophoneInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _availableMicrophones = [
            'Built-in Microphone',
            'Wired Headset',
            'Bluetooth Headset',
          ];
          _selectedMicrophone = 'Built-in Microphone';
          _microphoneInfo = '${androidInfo.model} - Built-in Mic';
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _availableMicrophones = [
            'Built-in Microphone',
            'Wired Headset',
            'Bluetooth Headset',
          ];
          _selectedMicrophone = 'Built-in Microphone';
          _microphoneInfo = '${iosInfo.model} - Built-in Mic';
        });
      }
    } catch (e) {
      debugPrint('Error loading microphone info: $e');
      setState(() {
        _availableMicrophones = ['Default Microphone'];
        _selectedMicrophone = 'Default Microphone';
        _microphoneInfo = 'Default Microphone';
      });
    }
  }

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Microphone permission not granted');
        if (mounted) {
          setState(() {
            _isRecorderInitialized = false;
            _microphoneInfo = 'Permission denied';
          });
        }
        return;
      }
      
      await _recorder.openRecorder();
      
      if (mounted) {
        setState(() {
          _isRecorderInitialized = true;
        });
      }
      
      debugPrint('Recorder initialized successfully');
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      if (mounted) {
        setState(() {
          _isRecorderInitialized = false;
          _microphoneInfo = 'Error: $e';
        });
      }
    }
  }

  void _showMicrophoneSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Microphone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _availableMicrophones.map((mic) {
            return RadioListTile<String>(
              title: Text(mic),
              value: mic,
              groupValue: _selectedMicrophone,
              onChanged: (value) {
                setState(() {
                  _selectedMicrophone = value;
                  _microphoneInfo = value ?? 'Unknown';
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> initRealtimeClient() async {
    try {
      client = RealtimeClient(
        apiKey: '', // chỉ dùng dev/demo
      );

      await client.updateSession(
        instructions: 'You are a helpful voice assistant.',
        voice: Voice.alloy, // chọn voice
        turnDetection: const TurnDetection(
          type: TurnDetectionType.serverVad,
        ),
        inputAudioTranscription: const InputAudioTranscriptionConfig(
          model: 'whisper-1',
        ),
      );

      client.on(RealtimeEventType.conversationUpdated, (event) {
        final delta = (event as RealtimeEventConversationUpdated).result.delta;
        if (delta?.audio != null) {
          // Thu thập các audio chunks
          _audioChunks.add(delta!.audio!);
          _isCollectingChunks = true;
          
          // Reset timer để đợi thêm chunks
          _playbackTimer?.cancel();
          _playbackTimer = Timer(const Duration(milliseconds: 300), () {
            // Sau 300ms không nhận chunk mới nữa thì ghép và phát
            _playCollectedAudio();
          });
        }
      });

      await client.connect(model:"gpt-realtime-mini");
      if (mounted) {
        setState(() => connected = true);
      }
    } catch (e) {
      debugPrint('Error initializing realtime client: $e');
      if (mounted) {
        setState(() => connected = false);
      }
    }
  }

  Future<void> _playCollectedAudio() async {
    if (_audioChunks.isEmpty || _isPlaying) {
      return;
    }
    
    _isPlaying = true;
    _isCollectingChunks = false;
    
    try {
      // Ghép tất cả các chunks lại
      final List<int> combinedBytes = [];
      for (final chunk in _audioChunks) {
        combinedBytes.addAll(chunk);
      }
      _audioChunks.clear();
      
      final audioBytes = Uint8List.fromList(combinedBytes);
      
      // PCM16 -> WAV
      final wav = pcm16ToWav(audioBytes, 24000);
      
      // Lưu file tạm để phát audio
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/audio_${_audioCounter++}.wav');
      await tempFile.writeAsBytes(wav);
      
      // Phát audio từ file
      await audioPlayer.play(DeviceFileSource(tempFile.path));
      
      // Chờ phát xong
      await audioPlayer.onPlayerComplete.first;
      
      // Xóa file tạm
      try {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
      
      _isPlaying = false;
      
      // Kiểm tra xem có chunks mới được thu thập trong lúc phát không
      if (_isCollectingChunks && _audioChunks.isNotEmpty) {
        // Đợi thêm một chút để thu thập đủ chunks
        await Future.delayed(const Duration(milliseconds: 300));
        _playCollectedAudio();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      _audioChunks.clear();
    }
  }

  Uint8List pcm16ToWav(Uint8List pcmBytes, int sampleRate) {
    // tạo WAV header cơ bản 16bit PCM mono
    int dataLength = pcmBytes.length;
    int fileLength = 44 + dataLength;
    final header = Uint8List(44);
    final byteData = ByteData.view(header.buffer);

    // RIFF
    byteData.setUint8(0, 'R'.codeUnitAt(0));
    byteData.setUint8(1, 'I'.codeUnitAt(0));
    byteData.setUint8(2, 'F'.codeUnitAt(0));
    byteData.setUint8(3, 'F'.codeUnitAt(0));

    byteData.setUint32(4, fileLength - 8, Endian.little);
    byteData.setUint8(8, 'W'.codeUnitAt(0));
    byteData.setUint8(9, 'A'.codeUnitAt(0));
    byteData.setUint8(10, 'V'.codeUnitAt(0));
    byteData.setUint8(11, 'E'.codeUnitAt(0));

    // fmt chunk
    byteData.setUint8(12, 'f'.codeUnitAt(0));
    byteData.setUint8(13, 'm'.codeUnitAt(0));
    byteData.setUint8(14, 't'.codeUnitAt(0));
    byteData.setUint8(15, ' '.codeUnitAt(0));
    byteData.setUint32(16, 16, Endian.little); // PCM
    byteData.setUint16(20, 1, Endian.little); // PCM format
    byteData.setUint16(22, 1, Endian.little); // mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // byteRate
    byteData.setUint16(32, 2, Endian.little); // blockAlign
    byteData.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    byteData.setUint8(36, 'd'.codeUnitAt(0));
    byteData.setUint8(37, 'a'.codeUnitAt(0));
    byteData.setUint8(38, 't'.codeUnitAt(0));
    byteData.setUint8(39, 'a'.codeUnitAt(0));
    byteData.setUint32(40, dataLength, Endian.little);

    return Uint8List.fromList(header + pcmBytes);
  }

  Future<void> sendText() async {
    try {
      final text = textController.text;
      if (text.isEmpty) return;
      if (!connected) {
        debugPrint('Client not connected yet');
        return;
      }
      await client.sendUserMessageContent([
        ContentPart.inputText(text: text),
      ]);
      textController.clear();
    } catch (e) {
      debugPrint('Error sending text: $e');
    }
  }

  Future<void> toggleRecording() async {
    if (!_isRecorderInitialized) {
      debugPrint('Recorder not initialized');
      return;
    }

    try {
      if (_isRecording) {
        // Stop recording
        final path = await _recorder.stopRecorder();
        if (path != null) {
          // Lưu path để có thể phát lại
          setState(() {
            _lastRecordingPath = path;
            _isRecording = false;
            _microphoneInfo = 'Recording saved';
          });
          
          debugPrint('Recording saved at: $path');
          final file = File(path);
          final fileSize = await file.length();
          debugPrint('Recording file size: $fileSize bytes');
        } else {
          setState(() => _isRecording = false);
        }
      } else {
        // Start recording
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        // Use default codec for WAV recording
        await _recorder.startRecorder(
          toFile: path,
          numChannels: 1,
          sampleRate: 24000,
        );
        setState(() {
          _isRecording = true;
          _microphoneInfo = 'Recording...';
        });
      }
    } catch (e) {
      debugPrint('Error toggling recording: $e');
      setState(() {
        _isRecording = false;
        _microphoneInfo = 'Error: $e';
      });
    }
  }

  Future<void> playRecording() async {
    if (_lastRecordingPath == null) {
      debugPrint('No recording to play');
      return;
    }
    
    try {
      await audioPlayer.play(DeviceFileSource(_lastRecordingPath!));
      debugPrint('Playing recording from: $_lastRecordingPath');
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }

  Future<void> sendRecording() async {
    if (_lastRecordingPath == null) {
      debugPrint('No recording to send');
      return;
    }
    
    if (!connected) {
      debugPrint('Client not connected yet');
      return;
    }

    try {
      final file = File(_lastRecordingPath!);
      final audioBytes = await file.readAsBytes();
      
      // Convert audio bytes to base64 string
      final base64Audio = base64Encode(audioBytes);
      
      debugPrint('Sending audio: ${audioBytes.length} bytes, base64: ${base64Audio.length} chars');
      
      // Gửi audio đến OpenAI Realtime API
      await client.sendUserMessageContent([
        ContentPart.inputAudio(audio: base64Audio),
      ]);
      
      setState(() {
        _microphoneInfo = 'Audio sent';
        _lastRecordingPath = null;
      });
      
      // Xóa file sau khi gửi
      await file.delete();
    } catch (e) {
      debugPrint('Error sending recording: $e');
      setState(() => _microphoneInfo = 'Error sending: $e');
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    client.disconnect();
    audioPlayer.dispose();
    _recorder.closeRecorder();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Speech Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Status: ${connected ? "Connected" : "Connecting..."}'),
            Text('Recorder: ${_isRecorderInitialized ? "Ready" : "Not Ready"}'),
            
            // Microphone selector
            InkWell(
              onTap: _showMicrophoneSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _microphoneInfo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Text input section
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Type something',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: sendText,
              child: const Text('Send Text'),
            ),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            
            // Speech-to-speech section
            const Text(
              'Speech to Speech',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Recording button
            GestureDetector(
              onTap: (connected && _isRecorderInitialized) ? toggleRecording : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.red
                      : (_isRecorderInitialized ? Colors.blue : Colors.grey),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue)
                          .withOpacity(0.5),
                      spreadRadius: _isRecording ? 10 : 5,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isRecording
                  ? 'Recording...'
                  : (_isRecorderInitialized ? 'Tap to record' : 'Initializing recorder...'),
              style: TextStyle(
                color: _isRecording ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Recording controls
            if (_lastRecordingPath != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: playRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: sendRecording,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
