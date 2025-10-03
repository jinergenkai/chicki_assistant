# Voice Controller Usage Guide

## Overview

The `VoiceController` now supports two modes of operation:

1. **Direct Mode** - Normal operation when the app is active
2. **Foreground Service Mode** - Runs in the background with a **persistent notification**, survives screen-off

## ✅ Notification Bar

**YES!** When you enable Foreground Service Mode, the app **WILL show a persistent notification** in the notification bar. This is:
- **Required by Android** for foreground services
- **Shows "Voice Assistant - Listening for wake word..."**
- **Includes a "Stop" button** to stop the service
- **Cannot be dismissed** while the service is running
- **Disappears** when you call `stopForegroundService()`

## ✅ Permissions

The implementation **automatically requests** the following Android permissions:

### Automatically Handled:
1. **Notification Permission (Android 13+)** - Requested when calling `startForegroundService()`
2. **Battery Optimization** - Prompts user to disable for better background performance
3. **Microphone Permission** - Already handled by `PermissionUtils.checkMicrophone()`

### Already in AndroidManifest.xml:
- `FOREGROUND_SERVICE` - Allows foreground service
- `FOREGROUND_SERVICE_MICROPHONE` - Specifies microphone usage
- `WAKE_LOCK` - Keeps device awake for processing
- `POST_NOTIFICATIONS` - Shows notifications
- `RECORD_AUDIO` - Microphone access

## Architecture

- **VoiceController** - Facade/proxy that manages both modes
- **VoiceForegroundTaskHandler** - Background service handler for foreground mode

## Usage

### 1. Direct Mode (Default)

When the app initializes, it automatically starts in direct mode:

```dart
final voiceController = Get.find<VoiceController>();

// Already initialized in main.dart
// await voiceController.initialize(); // Called automatically

// Start listening
await voiceController.startListening();

// Stop listening
await voiceController.stopListening();

// Stop speaking
await voiceController.stopSpeaking();
```

### 2. Switching to Foreground Service Mode

To enable background operation with **persistent notification** (survives screen-off):

```dart
final voiceController = Get.find<VoiceController>();

// Start foreground service
// This will:
// 1. Request notification permission (Android 13+)
// 2. Request battery optimization exemption
// 3. Show persistent notification
// 4. Start background service
try {
  await voiceController.startForegroundService();
  // Notification now visible in status bar!
} catch (e) {
  print('Failed to start foreground service: $e');
  // User may have denied notification permission
}

// Now the service runs in background
// All calls to startListening(), stopListening(), etc. are delegated to the service
// Notification remains visible until you call stopForegroundService()

// Check if foreground service is active
if (voiceController.isForegroundServiceActive) {
  print('Running in foreground service mode');
}
```

### 3. Switching Back to Direct Mode

To stop the foreground service and **remove the notification**:

```dart
await voiceController.stopForegroundService();
// Notification disappears
// Automatically returns to direct mode
```

### 4. Observing State Changes

The controller provides reactive observables:

```dart
// In a widget
Obx(() {
  switch (voiceController.state.value) {
    case VoiceState.idle:
      return Text('Idle');
    case VoiceState.listening:
      return Text('Listening...');
    case VoiceState.processing:
      return Text('Processing...');
    case VoiceState.speaking:
      return Text('Speaking...');
    default:
      return Text('Unknown state');
  }
});

// Recognized text
Obx(() => Text(voiceController.recognizedText.value));

// GPT response
Obx(() => Text(voiceController.gptResponse.value));

// RMS level (for visualizations)
Obx(() => Text('Volume: ${voiceController.rmsDB.value}'));
```

## Example: Toggle Between Modes

```dart
class VoiceControlWidget extends StatelessWidget {
  final voiceController = Get.find<VoiceController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => Switch(
          value: voiceController.isForegroundServiceActive,
          onChanged: (value) async {
            if (value) {
              await voiceController.startForegroundService();
            } else {
              await voiceController.stopForegroundService();
            }
          },
        )),
        Text('Background Mode'),
        
        ElevatedButton(
          onPressed: () => voiceController.startListening(),
          child: Text('Start Listening'),
        ),
        
        ElevatedButton(
          onPressed: () => voiceController.stopListening(),
          child: Text('Stop Listening'),
        ),
      ],
    );
  }
}
```

## Features

### Direct Mode
- ✅ Full access to all services
- ✅ Lower latency
- ✅ Works when app is active
- ✅ No persistent notification
- ❌ Stops when screen turns off
- ❌ Pauses when app goes to background

### Foreground Service Mode
- ✅ Runs when screen is off
- ✅ Survives app going to background
- ✅ **Shows persistent notification** (required by Android)
- ✅ Wake word detection works in background
- ✅ Auto-requests notification permission
- ✅ Auto-requests battery optimization exemption
- ⚠️ Slightly higher battery usage
- ⚠️ Persistent notification visible to user

## Communication Flow

### Direct Mode
```
UI → VoiceController → Services (STT/TTS/LLM) → UI Updates
```

### Foreground Service Mode
```
UI → VoiceController → FlutterForegroundTask.sendDataToTask() 
  → VoiceForegroundTaskHandler → Services 
  → FlutterForegroundTask.sendDataToMain() 
  → VoiceController → UI Updates
```

## Important Notes

1. **Permissions**:
   - Both modes require microphone permission (auto-requested)
   - Foreground service requires notification permission (auto-requested on Android 13+)
   - Battery optimization exemption is requested for better performance

2. **Notification**:
   - **Foreground service WILL show a persistent notification** - this is mandatory
   - Notification cannot be dismissed while service is running
   - Notification disappears when you call `stopForegroundService()`

3. **Battery**:
   - Foreground service uses more battery than direct mode
   - User is prompted to disable battery optimization for better reliability

4. **State Sync**:
   - State is automatically synchronized between modes
   - UI observables update in real-time from both modes

5. **Continuous Listening**:
   - Currently only supported in direct mode
   - Will be added to foreground service in future updates

## Troubleshooting

### Service won't start
- **Check notification permissions are granted** (Settings → Apps → Chicki Buddy → Notifications)
- Verify battery optimization is disabled for the app
- Check logcat for initialization errors
- On Android 13+, notification permission must be granted

### Notification not showing
- Ensure you called `startForegroundService()` not just `startListening()`
- Check notification permission is granted
- Verify `POST_NOTIFICATIONS` permission in AndroidManifest.xml

### Service stops after a while
- Disable battery optimization for the app
- Check if system is aggressively killing background apps
- Verify `WAKE_LOCK` permission is in AndroidManifest.xml

### State not updating in UI
- Ensure `FlutterForegroundTask.initCommunicationPort()` is called in `main()`
- Check foreground data subscription is active
- Verify the controller is observing state changes with `Obx()`

### Audio stops when screen turns off (Direct Mode)
- This is expected behavior in Direct Mode
- **Solution**: Call `startForegroundService()` before screen turns off
- Verify wake lock permissions are granted

### Permission denied errors
- Check AndroidManifest.xml has all required permissions
- Request permissions before starting service
- On Android 13+, notification permission is required