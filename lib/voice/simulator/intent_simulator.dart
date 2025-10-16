import '../core/voice_isolate_manager.dart';
import '../models/voice_intent_payload.dart';

/// Simple simulator to emit test intents to the background isolate
class IntentSimulator {
  final VoiceIsolateManager _manager = VoiceIsolateManager();

  /// Emit a selectBook intent
  void emitSelectBook(String bookName) {
    _manager.dispatchIntent(
      VoiceIntentPayload(
        intent: 'selectBook',
        slots: {'bookName': bookName},
        confidence: 1.0,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Emit a selectTopic intent
  void emitSelectTopic(String topicName) {
    _manager.dispatchIntent(
      VoiceIntentPayload(
        intent: 'selectTopic',
        slots: {'topicName': topicName},
        confidence: 1.0,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Emit a nextVocab intent
  void emitNextVocab() {
    _manager.dispatchIntent(
      VoiceIntentPayload(
        intent: 'nextVocab',
        slots: {},
        confidence: 1.0,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Emit a readAloud intent
  void emitReadAloud() {
    _manager.dispatchIntent(
      VoiceIntentPayload(
        intent: 'readAloud',
        slots: {},
        confidence: 1.0,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Emit a custom intent
  void emitCustom(String intent, Map<String, dynamic> slots) {
    _manager.dispatchIntent(
      VoiceIntentPayload(
        intent: intent,
        slots: slots,
        confidence: 1.0,
        timestamp: DateTime.now(),
      ),
    );
  }
}