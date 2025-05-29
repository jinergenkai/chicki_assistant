## Flutter App Voice AI - Clean Architecture Code Generation Rules

Generate a Flutter app with the following rules:

### 1. 🧱 Architecture
loose coupling
using interfaces.
lib/
│
├── main.dart                   # App entry point
│
├── core/                       # Core utilities & configs
│   ├── constants.dart
│   ├── app_config.dart
│   └── logger.dart
│
├── services/                   # Service layer: voice, GPT API, TTS/STT
│   ├── stt_service.dart
│   ├── tts_service.dart
│   ├── gpt_service.dart
│   └── voice_controller.dart   # Orchestrate STT <-> GPT <-> TTS
│
├── ui/                         # UI screens and widgets
│   ├── screens/
│   │   └── home_screen.dart
│   └── widgets/
│       └── mic_button.dart
│
├── models/                     # Models (prompt, chat log, etc.)
│   └── message.dart
│
└── utils/                      # Helper functions
    └── translator.dart         # Optional: translate vi <-> en

- Use **clean architecture**.
- Each service should be injected via constructor to promote loose coupling.

### 2. 🗣 Wake Word Module

- Define a `WakeWordService` abstract class with:
  ```dart
  abstract class WakeWordService {
    Future<void> start();
    Future<void> stop();
    Stream<void> get onWakeWordDetected;
  }