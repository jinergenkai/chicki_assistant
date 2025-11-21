import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/core/logger.dart';
import 'package:get/get.dart';

/// Example showing how to use the unified intent system
/// This demonstrates both UI-triggered and speech-triggered intents
class UnifiedIntentUsageExample extends GetxController {
  
  @override
  void onInit() {
    super.onInit();
    _setupEventListeners();
  }
  
  void _setupEventListeners() {
    // Listen for voice action results
    eventBus.stream
        .where((event) => event.type == AppEventType.voiceAction)
        .listen((event) {
      final action = event.payload as Map<String, dynamic>;
      _handleVoiceAction(action);
    });
  }
  
  /// Example: User clicks "List Books" button in UI
  Future<void> onListBooksButtonPressed() async {
    logger.info('User clicked List Books button');
    
    // This will trigger the intent in foreground isolate
    // and return full data for UI display
    // IntentBridgeService.triggerUIIntent(
    //   intent: 'listBook',
    // );
  }
  
  /// Example: User clicks "Select Book" with a specific book
  Future<void> onSelectBookButtonPressed(String bookName) async {
    logger.info('User clicked Select Book: $bookName');
    
    // IntentBridgeService.triggerUIIntent(
    //   intent: 'selectBook',
    //   slots: {'bookName': bookName},
    // );
  }
  
  /// Example: User says "List my books" (handled automatically by speech system)
  /// This is just for documentation - speech intents are processed automatically
  /// in VoiceForegroundTaskHandler when user speaks
  void onSpeechDetected(String text) {
    // This happens automatically:
    // 1. VoiceForegroundTaskHandler receives speech
    // 2. LLMIntentClassifierService classifies intent
    // 3. UnifiedIntentHandler processes with IntentSource.speech
    // 4. Returns minimal response for TTS
    logger.info('Speech detected: $text (processed automatically)');
  }
  
  /// Handle voice action results from foreground isolate
  void _handleVoiceAction(Map<String, dynamic> action) {
    final actionType = action['action'] as String?;
    final data = action['data'] as Map<String, dynamic>?;
    final requiresUI = action['requiresUI'] as bool? ?? false;
    
    logger.info('Handling voice action: $actionType, requiresUI: $requiresUI');
    
    switch (actionType) {
      case 'listBook':
        if (requiresUI && data != null) {
          final books = data['books'] as List?;
          logger.info('Received ${books?.length ?? 0} books for UI display');
          // Update UI with books list
          _updateBooksUI(books);
        }
        break;
        
      case 'selectBook':
        if (requiresUI && data != null) {
          final bookId = data['bookId'] as String?;
          final bookName = data['bookName'] as String?;
          logger.info('Navigating to book: $bookName ($bookId)');
          // Navigate to book screen
          _navigateToBook(bookId, bookName);
        }
        break;
        
      case 'speak':
        // This is handled by TTS in foreground isolate
        // UI doesn't need to do anything
        final text = action['text'] as String?;
        logger.info('TTS will speak: $text');
        break;
        
      case 'error':
        final error = data?['error'] as String?;
        logger.error('Intent error: $error');
        // Show error to user
        _showError(error);
        break;
        
      default:
        logger.warning('Unknown voice action: $actionType');
    }
  }
  
  void _updateBooksUI(List? books) {
    // Update your books controller or UI state
    logger.info('Updating books UI with ${books?.length ?? 0} books');
  }
  
  void _navigateToBook(String? bookId, String? bookName) {
    // Navigate to book details screen
    if (bookId != null) {
      Get.toNamed('/book/$bookId');
    }
  }
  
  void _showError(String? error) {
    // Show error message to user
    if (error != null) {
      Get.snackbar('Error', error);
    }
  }
}

/// Usage in your existing controllers:
/// 
/// class BooksController extends GetxController {
///   
///   // Replace direct service calls with intent bridge
///   Future<void> loadBooks() async {
///     // Old way:
///     // books.value = await bookService.loadAllBooks();
///     
///     // New way:
///     await IntentBridgeService.triggerUIIntent(intent: 'listBook');
///     // Result will come through event bus and update UI
///   }
/// }