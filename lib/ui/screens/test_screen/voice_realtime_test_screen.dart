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
import 'dart:io';

// ==================== ENUMS & MODELS ====================

/// Voice Activity Detection Status
enum VoiceActivityStatus {
  silence,
  speaking,
  endOfSpeech,
}

/// Realtime Voice State Machine
enum RealtimeVoiceState {
  idle,           // Waiting for user to start
  listening,      // Mic active, monitoring for speech
  processing,     // Sending audio, waiting for response
  receiving,      // Getting audio chunks from server
  playing,        // Playing response audio
}

/// Conversation Mode - How user can interact during assistant speech
enum ConversationMode {
  interruptible,  // User can interrupt assistant anytime
  turnBased,      // User waits for assistant to finish before speaking
}

// ==================== VAD DETECTOR ====================

/// Voice Activity Detector - detects speech vs silence
class VoiceActivityDetector {
  // Amplitude threshold (0.0-1.0 range)
  // Formula: amplitude = decibels / 60
  // Examples:
  //   0.50 = 30 dB (normal speech)
  //   0.67 = 40 dB (louder speech)
  //   0.83 = 50 dB (loud speech)
  static const double speechThreshold = 0.85; // Currently set to 30 dB
  static const int silenceDurationMs = 1500;  // 1.5s silence = end
  static const int minSpeechDurationMs = 300; // Min 300ms speech
  
  // Helper: Convert dB to amplitude
  static double dbToAmplitude(double db) => (db / 60).clamp(0.0, 1.0);
  
  // Helper: Convert amplitude to dB
  static double amplitudeToDb(double amp) => amp * 60;
  
  double _lastAmplitude = 0.0;
  DateTime? _lastSpeechTime;
  DateTime? _speechStartTime;
  bool _isSpeaking = false;
  
  double get currentAmplitude => _lastAmplitude;
  bool get isSpeaking => _isSpeaking;
  
  VoiceActivityStatus analyze(double amplitude) {
    _lastAmplitude = amplitude;
    
    if (amplitude > speechThreshold) {
      // Speech detected
      if (!_isSpeaking) {
        _speechStartTime = DateTime.now();
        _isSpeaking = true;
      }
      _lastSpeechTime = DateTime.now();
      return VoiceActivityStatus.speaking;
    } else {
      // Check for silence duration
      if (_lastSpeechTime != null && _isSpeaking) {
        final silenceDuration = DateTime.now()
            .difference(_lastSpeechTime!)
            .inMilliseconds;
            
        if (silenceDuration > silenceDurationMs) {
          // End of speech detected
          final speechDuration = _speechStartTime != null
              ? DateTime.now().difference(_speechStartTime!).inMilliseconds
              : 0;
              
          _isSpeaking = false;
          _speechStartTime = null;
          _lastSpeechTime = null;
          
          if (speechDuration > minSpeechDurationMs) {
            return VoiceActivityStatus.endOfSpeech;
          }
        }
      }
      return VoiceActivityStatus.silence;
    }
  }
  
  void reset() {
    _lastAmplitude = 0.0;
    _lastSpeechTime = null;
    _speechStartTime = null;
    _isSpeaking = false;
  }
}

// ==================== MAIN SCREEN ====================

class VoiceRealtimeTestScreen extends StatefulWidget {
  const VoiceRealtimeTestScreen({super.key});

  @override
  State<VoiceRealtimeTestScreen> createState() => _VoiceRealtimeTestScreenState();
}

class _VoiceRealtimeTestScreenState extends State<VoiceRealtimeTestScreen> {
  // OpenAI Client
  late RealtimeClient client;
  bool connected = false;
  
  // Audio components
  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  
  // State management
  RealtimeVoiceState _state = RealtimeVoiceState.idle;
  final VoiceActivityDetector _vad = VoiceActivityDetector();
  ConversationMode _conversationMode = ConversationMode.interruptible;
  
  // Audio streaming
  StreamSubscription? _audioStreamSubscription;
  final List<Uint8List> _audioBuffer = [];
  Timer? _vadTimer;
  int _audioCounter = 0;
  
  // Audio playback
  final List<Uint8List> _responseAudioChunks = [];
  bool _isPlaying = false;
  Timer? _playbackTimer;
  
  // UI
  String _statusMessage = 'Tap mic to start';
  double _currentAmplitude = 0.0;
  StreamSubscription? _recorderProgressSubscription;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initRealtimeClient();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _updateStatus('Microphone permission denied');
        return;
      }
      
      await _recorder.openRecorder();
      
      // Start monitoring audio level immediately (even when idle)
      _startAmplitudeMonitoring();
      
      if (mounted) {
        setState(() {
          _isRecorderInitialized = true;
        });
      }
      
      debugPrint('✅ Recorder initialized');
    } catch (e) {
      debugPrint('❌ Error initializing recorder: $e');
      _updateStatus('Error: $e');
    }
  }

  Future<void> _initRealtimeClient() async {
    try {
      client = RealtimeClient(
        apiKey: '',
      );

      await client.updateSession(
        instructions: 'You are a helpful voice assistant. Keep responses concise and natural.',
        voice: Voice.alloy,
        turnDetection: const TurnDetection(
          type: TurnDetectionType.serverVad,
        ),
        inputAudioTranscription: const InputAudioTranscriptionConfig(
          model: 'whisper-1',
        ),
      );

      // Listen for audio response chunks
      client.on(RealtimeEventType.conversationUpdated, (event) {
        _handleConversationUpdate(event as RealtimeEventConversationUpdated);
      });

      await client.connect(model: "gpt-realtime-mini");
      
      if (mounted) {
        setState(() {
          connected = true;
        });
        _updateStatus('Connected - Tap mic to start');
      }
      
      debugPrint('✅ Realtime client connected');
    } catch (e) {
      debugPrint('❌ Error initializing client: $e');
      _updateStatus('Connection failed');
    }
  }

  // ==================== CONVERSATION HANDLING ====================

  void _handleConversationUpdate(RealtimeEventConversationUpdated event) {
    debugPrint('📥 Received conversation update');
    final delta = event.result.delta;
    if (delta?.audio != null) {
      debugPrint('🔊 Received audio chunk: ${delta!.audio!.length} bytes');
      _responseAudioChunks.add(delta.audio!);
      
      if (_state != RealtimeVoiceState.playing) {
        _transitionToState(RealtimeVoiceState.receiving);
      }
      
      // Start playback timer
      _playbackTimer?.cancel();
      _playbackTimer = Timer(const Duration(milliseconds: 300), () {
        _playResponseAudio();
      });
    } else {
      debugPrint('📥 Conversation update with no audio');
    }
  }

  // ==================== STATE MANAGEMENT ====================

  void _transitionToState(RealtimeVoiceState newState) {
    if (_state == newState) return;
    
    debugPrint('🔄 State: $_state → $newState');
    setState(() {
      _state = newState;
    });
    
    // Update status message based on state
    switch (newState) {
      case RealtimeVoiceState.idle:
        _updateStatus('Tap mic to start');
        break;
      case RealtimeVoiceState.listening:
        _updateStatus('Listening...');
        break;
      case RealtimeVoiceState.processing:
        _updateStatus('Processing...');
        break;
      case RealtimeVoiceState.receiving:
        _updateStatus('Receiving response...');
        break;
      case RealtimeVoiceState.playing:
        if (_conversationMode == ConversationMode.interruptible) {
          _updateStatus('Assistant speaking - You can interrupt');
        } else {
          _updateStatus('Assistant speaking - Wait for your turn');
        }
        break;
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  // ==================== AMPLITUDE MONITORING ====================

  void _startAmplitudeMonitoring() {
    // Amplitude monitoring will be active only during recording
    // via the onProgress stream listener
    debugPrint('✅ Amplitude monitoring ready');
  }

  // ==================== REALTIME RECORDING ====================

  Future<void> _startRealtimeRecording() async {
    if (!_isRecorderInitialized || !connected) {
      debugPrint('❌ Not ready to start recording');
      return;
    }

    try {
      _transitionToState(RealtimeVoiceState.listening);
      _vad.reset();
      _audioBuffer.clear();

      // Start recording to file
      final tempDir = await getTemporaryDirectory();
      final recordPath = '${tempDir.path}/realtime_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // Set subscription duration for frequent progress updates (100ms)
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      
      await _recorder.startRecorder(
        toFile: recordPath,
        numChannels: 1,
        sampleRate: 24000,
      );

      debugPrint('🎤 Started realtime recording to: $recordPath');

      // Start periodic file reading to stream audio chunks
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (_state != RealtimeVoiceState.listening) {
          timer.cancel();
          return;
        }

        try {
          final file = File(recordPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (bytes.length > _audioBuffer.fold<int>(0, (sum, chunk) => sum + chunk.length)) {
              // New audio data available
              final newDataLength = bytes.length - _audioBuffer.fold<int>(0, (sum, chunk) => sum + chunk.length);
              final newChunk = bytes.sublist(bytes.length - newDataLength);
              
              debugPrint('📤 Streaming new audio chunk: ${newChunk.length} bytes');
              _audioBuffer.add(newChunk);
              
              // Send to OpenAI immediately
              try {
                client.appendInputAudio(newChunk);
                debugPrint('✅ Audio chunk sent to server');
              } catch (e) {
                debugPrint('❌ Error sending audio chunk: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error reading audio file: $e');
        }
      });

      // Start VAD monitoring with onProgress
      _recorderProgressSubscription?.cancel();
      _recorderProgressSubscription = _recorder.onProgress!.listen((event) {
        final rawDecibels = event.decibels;
        
        // Calculate amplitude from decibels
        final decibels = rawDecibels ?? 0.0;
        final amplitude = _decibelToAmplitude(decibels);
        
        if (mounted) {
          setState(() {
            _currentAmplitude = amplitude;
          });
        }
        
        // Monitor VAD
        _monitorVAD();
      });
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _updateStatus('Error: $e');
    }
  }

  double _decibelToAmplitude(double decibels) {
    // flutter_sound returns positive decibels (0-120 range typically)
    // 0 dB = very quiet, 30-40 dB = normal speech, 60+ dB = loud
    // We normalize to 0.0-1.0 range
    if (decibels <= 0) return 0.0;
    if (decibels >= 60) return 1.0;
    return (decibels / 60).clamp(0.0, 1.0); // Normalize 0-60 dB to 0-1
  }

  void _handleAudioStream(Uint8List audioChunk) {
    if (_state == RealtimeVoiceState.idle) return;

    // Buffer audio
    _audioBuffer.add(audioChunk);

    // Send to OpenAI (streaming) - OpenAI expects Uint8List directly
    try {
      debugPrint('📤 Sending audio chunk: ${audioChunk.length} bytes');
      client.appendInputAudio(audioChunk);
      debugPrint('✅ Audio chunk sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending audio chunk: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  void _monitorVAD() {
    if (_state == RealtimeVoiceState.idle) return;

    final vadStatus = _vad.analyze(_currentAmplitude);

    switch (vadStatus) {
      case VoiceActivityStatus.speaking:
        if (_state == RealtimeVoiceState.listening) {
          _updateStatus('Speaking...');
        } else if (_conversationMode == ConversationMode.interruptible &&
                   (_state == RealtimeVoiceState.playing ||
                    _state == RealtimeVoiceState.receiving)) {
          // User interrupted - only in interruptible mode
          _handleInterrupt();
        }
        // In turn-based mode, ignore user speech while assistant is speaking
        break;

      case VoiceActivityStatus.endOfSpeech:
        if (_state == RealtimeVoiceState.listening) {
          _commitAudio();
        }
        break;

      case VoiceActivityStatus.silence:
        // Just waiting
        break;
    }
  }

  Future<void> _commitAudio() async {
    if (_audioBuffer.isEmpty) {
      debugPrint('⚠️ Audio buffer is empty, skipping commit');
      return;
    }

    debugPrint('📤 Committing audio (${_audioBuffer.length} chunks)');
    _transitionToState(RealtimeVoiceState.processing);

    try {
      // Signal OpenAI that input is complete
      debugPrint('🔄 Calling client.createResponse()...');
      await client.createResponse();
      debugPrint('✅ createResponse() succeeded');
      _audioBuffer.clear();
    } catch (e) {
      debugPrint('❌ Error committing audio: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      _stopRealtimeRecording();
    }
  }

  Future<void> _stopRealtimeRecording() async {
    _vadTimer?.cancel();
    _vadTimer = null;
    
    _recorderProgressSubscription?.cancel();
    _recorderProgressSubscription = null;

    try {
      await _recorder.stopRecorder();
    } catch (e) {
      debugPrint('❌ Error stopping recorder: $e');
    }

    _audioBuffer.clear();
    _vad.reset();

    if (_state != RealtimeVoiceState.playing &&
        _state != RealtimeVoiceState.receiving) {
      _transitionToState(RealtimeVoiceState.idle);
    }

    debugPrint('🛑 Stopped realtime recording');
  }

  // ==================== INTERRUPT HANDLING ====================

  Future<void> _handleInterrupt() async {
    debugPrint('⚡ INTERRUPT detected - user speaking');

    // Stop current audio playback
    await audioPlayer.stop();
    _isPlaying = false;
    _responseAudioChunks.clear();
    _playbackTimer?.cancel();

    // Cancel server response - send empty response request to interrupt
    try {
      debugPrint('🔄 Calling client.createResponse() to interrupt...');
      // Truncate the current response by creating a new one
      await client.createResponse();
      debugPrint('✅ Interrupt successful');
    } catch (e) {
      debugPrint('❌ Error interrupting response: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }

    // Restart recording
    _transitionToState(RealtimeVoiceState.listening);
    _updateStatus('Interrupted - Listening...');
  }

  // ==================== AUDIO PLAYBACK ====================

  Future<void> _playResponseAudio() async {
    if (_responseAudioChunks.isEmpty || _isPlaying) {
      return;
    }

    _isPlaying = true;
    _transitionToState(RealtimeVoiceState.playing);

    try {
      // Combine all chunks
      final List<int> combinedBytes = [];
      for (final chunk in _responseAudioChunks) {
        combinedBytes.addAll(chunk);
      }
      _responseAudioChunks.clear();

      final audioBytes = Uint8List.fromList(combinedBytes);

      // Convert PCM16 to WAV
      final wav = _pcm16ToWav(audioBytes, 24000);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/response_${_audioCounter++}.wav');
      await tempFile.writeAsBytes(wav);

      // Play audio
      await audioPlayer.play(DeviceFileSource(tempFile.path));

      // Wait for playback to complete
      await audioPlayer.onPlayerComplete.first;

      // Cleanup
      try {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('❌ Error deleting temp file: $e');
      }

      _isPlaying = false;

      // Check if there are more chunks
      if (_responseAudioChunks.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
        _playResponseAudio();
      } else {
        // Playback complete
        if (_conversationMode == ConversationMode.turnBased) {
          // Turn-based: Auto-start recording for user's turn
          await _startRealtimeRecording();
        } else {
          // Interruptible: Return to idle, wait for user tap
          _transitionToState(RealtimeVoiceState.idle);
        }
      }
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');
      _isPlaying = false;
      _responseAudioChunks.clear();
      _transitionToState(RealtimeVoiceState.idle);
    }
  }

  // ==================== AUDIO UTILS ====================

  double _calculateAmplitude(Uint8List audioData) {
    if (audioData.isEmpty) return 0.0;

    double sum = 0.0;
    for (int i = 0; i < audioData.length; i += 2) {
      if (i + 1 < audioData.length) {
        // Convert bytes to 16-bit PCM sample
        int sample = (audioData[i + 1] << 8) | audioData[i];
        // Handle signed 16-bit
        if (sample > 32767) sample -= 65536;
        sum += (sample / 32768.0).abs();
      }
    }

    return sum / (audioData.length / 2);
  }

  Uint8List _pcm16ToWav(Uint8List pcmBytes, int sampleRate) {
    int dataLength = pcmBytes.length;
    int fileLength = 44 + dataLength;
    final header = Uint8List(44);
    final byteData = ByteData.view(header.buffer);

    // RIFF header
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
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);

    // data chunk
    byteData.setUint8(36, 'd'.codeUnitAt(0));
    byteData.setUint8(37, 'a'.codeUnitAt(0));
    byteData.setUint8(38, 't'.codeUnitAt(0));
    byteData.setUint8(39, 'a'.codeUnitAt(0));
    byteData.setUint32(40, dataLength, Endian.little);

    return Uint8List.fromList(header + pcmBytes);
  }

  // ==================== UI HELPERS ====================

  Color _getStateColor() {
    switch (_state) {
      case RealtimeVoiceState.idle:
        return Colors.grey;
      case RealtimeVoiceState.listening:
        return _vad.isSpeaking ? Colors.green : Colors.blue;
      case RealtimeVoiceState.processing:
        return Colors.orange;
      case RealtimeVoiceState.receiving:
        return Colors.purple;
      case RealtimeVoiceState.playing:
        return Colors.red;
    }
  }

  IconData _getStateIcon() {
    switch (_state) {
      case RealtimeVoiceState.idle:
        return Icons.mic;
      case RealtimeVoiceState.listening:
        return Icons.mic;
      case RealtimeVoiceState.processing:
        return Icons.sync;
      case RealtimeVoiceState.receiving:
        return Icons.download;
      case RealtimeVoiceState.playing:
        return Icons.volume_up;
    }
  }

  Future<void> _toggleRealtime() async {
    if (_state == RealtimeVoiceState.idle) {
      await _startRealtimeRecording();
    } else {
      await _stopRealtimeRecording();
    }
  }

  // ==================== LIFECYCLE ====================

  @override
  void dispose() {
    _vadTimer?.cancel();
    _playbackTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _recorderProgressSubscription?.cancel();
    client.disconnect();
    audioPlayer.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Voice Realtime Mode'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Status indicator
                _buildStatusCard(),
                
                const SizedBox(height: 16),
                
                // Conversation mode toggle
                _buildModeToggle(),
                
                const SizedBox(height: 16),
                
                // Audio amplitude meter (compact)
                if (_state != RealtimeVoiceState.idle) _buildAmplitudeMeter(),
                if (_state != RealtimeVoiceState.idle) const SizedBox(height: 16),
                
                // Voice visualizer
                _buildVoiceVisualizer(),
                
                const SizedBox(height: 20),
                
                // Status message
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // State info
                Text(
                  'State: ${_state.toString().split('.').last}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                _buildInstructions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            'Connection',
            connected ? 'Connected' : 'Disconnected',
            connected ? Colors.green : Colors.red,
          ),
          _buildStatusItem(
            'Recorder',
            _isRecorderInitialized ? 'Ready' : 'Not Ready',
            _isRecorderInitialized ? Colors.green : Colors.orange,
          ),
          _buildStatusItem(
            'VAD',
            _currentAmplitude > VoiceActivityDetector.speechThreshold ? 'Speaking' : 'Silent',
            _currentAmplitude > VoiceActivityDetector.speechThreshold ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.swap_horiz,
            size: 16,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            'Mode:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(
                  'Interruptible',
                  ConversationMode.interruptible,
                  Icons.fast_forward,
                ),
                const SizedBox(width: 8),
                _buildModeButton(
                  'Turn-based',
                  ConversationMode.turnBased,
                  Icons.swap_calls,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, ConversationMode mode, IconData icon) {
    final isSelected = _conversationMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _conversationMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : Colors.grey[500],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmplitudeMeter() {
    // Get decibel value from amplitude (reverse calculation)
    final decibels = _currentAmplitude > 0
        ? (_currentAmplitude * 60).clamp(0.0, 60.0)
        : 0.0;
    
    // Determine if threshold is exceeded
    final isAboveThreshold = _currentAmplitude > VoiceActivityDetector.speechThreshold;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header - compact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 14,
                    color: isAboveThreshold ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Audio',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${decibels.toStringAsFixed(0)} dB',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAboveThreshold ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isAboveThreshold) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.green[400],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Amplitude bar - compact
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                // Background
                Container(
                  height: 6,
                  color: Colors.grey[800],
                ),
                
                // Amplitude fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: _currentAmplitude * MediaQuery.of(context).size.width * 0.85,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        isAboveThreshold ? Colors.green : Colors.blue,
                        if (_currentAmplitude > 0.7) Colors.orange,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceVisualizer() {
    final stateColor = _getStateColor();
    final isActive = _state != RealtimeVoiceState.idle;
    final scale = 1.0 + (_currentAmplitude * 2).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: (connected && _isRecorderInitialized) ? _toggleRealtime : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 150 * scale,
        height: 150 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: stateColor,
          boxShadow: [
            BoxShadow(
              color: stateColor.withOpacity(0.5),
              spreadRadius: isActive ? 20 * scale : 10,
              blurRadius: 30,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _getStateIcon(),
            color: Colors.white,
            size: 60,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Instructions',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (_conversationMode == ConversationMode.interruptible) ...[
            _buildInstructionItem('• Tap mic to start/stop'),
            _buildInstructionItem('• Speak, pause 1.5s to send'),
            _buildInstructionItem('• Interrupt by speaking anytime'),
          ] else ...[
            _buildInstructionItem('• Tap mic to start conversation'),
            _buildInstructionItem('• Speak, pause 1.5s to send'),
            _buildInstructionItem('• Wait for assistant to finish'),
            _buildInstructionItem('• Auto-recording after assistant speaks'),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}