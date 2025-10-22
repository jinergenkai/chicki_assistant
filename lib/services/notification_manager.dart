import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:chicki_buddy/services/voice_foreground_task_handler.dart';

/// Modern notification manager for foreground task
/// Syncs notification UI with voice state and provides actionable buttons
class NotificationManager {
  
  /// Update notification based on voice state
  static void updateForState(VoiceState state, {String? additionalInfo}) {
    switch (state) {
      case VoiceState.uninitialized:
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: 'Initializing...',
          buttons: [],
        );
        break;
        
      case VoiceState.needsPermission:
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: '⚠️ Microphone permission needed',
          buttons: [
            const NotificationButton(id: 'open_app', text: 'Open App'),
          ],
        );
        break;
        
      case VoiceState.idle:
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: '💤 Ready - Say "Hey Chicky" or tap to start',
          buttons: [
            const NotificationButton(id: 'start_listening', text: '🎙️ Listen'),
            const NotificationButton(id: 'open_app', text: '📱 Open'),
          ],
        );
        break;
        
      case VoiceState.detecting:
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: '👂 Detecting wake word...',
          buttons: [
            const NotificationButton(id: 'stop_detecting', text: '⏸️ Pause'),
            const NotificationButton(id: 'open_app', text: '📱 Open'),
          ],
        );
        break;
        
      case VoiceState.listening:
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: '🎙️ Listening... Speak now!',
          buttons: [
            const NotificationButton(id: 'stop_listening', text: '⏹️ Stop'),
            const NotificationButton(id: 'open_app', text: '📱 Open'),
          ],
        );
        break;
        
      case VoiceState.processing:
        final text = additionalInfo != null && additionalInfo.isNotEmpty
            ? '🤔 Processing: "$additionalInfo"'
            : '🤔 Processing your request...';
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: text,
          buttons: [
            const NotificationButton(id: 'cancel', text: '❌ Cancel'),
            const NotificationButton(id: 'open_app', text: '📱 Open'),
          ],
        );
        break;
        
      case VoiceState.speaking:
        final text = additionalInfo != null && additionalInfo.isNotEmpty
            ? '🗣️ Speaking: "$additionalInfo"'
            : '🗣️ Speaking...';
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: text,
          buttons: [
            const NotificationButton(id: 'stop_speaking', text: '🔇 Stop'),
            const NotificationButton(id: 'open_app', text: '📱 Open'),
          ],
        );
        break;
        
      case VoiceState.error:
        final errorText = additionalInfo ?? 'An error occurred';
        _updateNotification(
          title: '🎤 Voice Assistant',
          text: '❌ Error: $errorText',
          buttons: [
            const NotificationButton(id: 'retry', text: '🔄 Retry'),
            const NotificationButton(id: 'open_app', text: '📱 Open'),
          ],
        );
        break;
    }
  }
  
  /// Update notification with custom content
  static void _updateNotification({
    required String title,
    required String text,
    required List<NotificationButton> buttons,
  }) {
    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationButtons: buttons,
    );
  }
  
  /// Show progress notification (for long operations)
  static void showProgress({
    required String title,
    required String text,
    required int progress, // 0-100
  }) {
    // Note: FlutterForegroundTask doesn't support progress bars directly
    // We can simulate with text
    final progressBar = _createProgressBar(progress);
    _updateNotification(
      title: title,
      text: '$text\n$progressBar $progress%',
      buttons: [
        const NotificationButton(id: 'cancel', text: '❌ Cancel'),
      ],
    );
  }
  
  /// Create ASCII progress bar
  static String _createProgressBar(int progress) {
    final filled = (progress / 10).floor();
    final empty = 10 - filled;
    return '[${'█' * filled}${'░' * empty}]';
  }
  
  /// Show notification with recognized text
  static void showRecognizedText(String text) {
    final displayText = text.length > 50 
        ? '${text.substring(0, 47)}...' 
        : text;
    _updateNotification(
      title: '🎤 Voice Assistant',
      text: '📝 You said: "$displayText"',
      buttons: [
        const NotificationButton(id: 'cancel', text: '❌ Cancel'),
        const NotificationButton(id: 'open_app', text: '📱 Open'),
      ],
    );
  }
  
  /// Show notification with intent result
  static void showIntentResult(String intent, String? response) {
    final text = response != null && response.isNotEmpty
        ? '✅ $intent: $response'
        : '✅ Completed: $intent';
    _updateNotification(
      title: '🎤 Voice Assistant',
      text: text,
      buttons: [
        const NotificationButton(id: 'start_listening', text: '🎙️ Again'),
        const NotificationButton(id: 'open_app', text: '📱 Open'),
      ],
    );
  }
  
  /// Show notification with RMS level (audio visualization)
  static void showListeningWithLevel(double rmsDB) {
    // Convert RMS to visual bars (0-5 bars)
    final level = (rmsDB / 20).clamp(0, 5).floor();
    final bars = '🔊${'▁' * (5 - level)}${'▆' * level}';
    
    _updateNotification(
      title: '🎤 Voice Assistant',
      text: '🎙️ Listening... $bars',
      buttons: [
        const NotificationButton(id: 'stop_listening', text: '⏹️ Stop'),
        const NotificationButton(id: 'open_app', text: '📱 Open'),
      ],
    );
  }
}