abstract class STTService {
  Future<void> initialize();
  Future<void> startListening();
  Future<void> stopListening();
  Stream<String> get onResult;
  bool get isListening;
}