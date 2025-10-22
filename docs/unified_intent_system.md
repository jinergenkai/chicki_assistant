# Unified Intent System Documentation

## Overview

The Unified Intent System simplifies intent handling by providing a single handler that works for both UI clicks and speech commands, while maintaining the flexibility of the WorkflowGraph system.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interaction                         │
├──────────────────────┬──────────────────────────────────────┤
│   UI Click           │         Speech Command                │
│   (Button/Tap)       │         ("list books")                │
└──────────┬───────────┴────────────────┬─────────────────────┘
           │                            │
           │                            ▼
           │                   ┌────────────────────┐
           │                   │ LLM Classifier     │
           │                   │ (Speech → Intent)  │
           │                   └────────┬───────────┘
           │                            │
           ▼                            ▼
    ┌──────────────────────────────────────────────┐
    │      IntentBridgeService.triggerIntent()     │
    │      (Send to Foreground Isolate)            │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │    VoiceForegroundTaskHandler                │
    │    (Receives intent + source)                │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │    UnifiedIntentHandler                      │
    │    - Validates against WorkflowGraph         │
    │    - Updates context/state                   │
    │    - Executes intent logic                   │
    │    - Returns different data based on source  │
    └──────────────────┬───────────────────────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
           ▼                       ▼
    ┌─────────────┐        ┌─────────────┐
    │ UI Source   │        │Speech Source│
    │ Full Data   │        │ TTS Text    │
    │ requiresUI  │        │ Minimal     │
    └──────┬──────┘        └──────┬──────┘
           │                      │
           └──────────┬───────────┘
                      │
                      ▼
           ┌────────────────────┐
           │   Event Bus        │
           │   (voiceAction)    │
           └─────────┬──────────┘
                     │
                     ▼
           ┌────────────────────┐
           │   Controller       │
           │   (Updates UI)     │
           └────────────────────┘
```

## Key Components

### 1. UnifiedIntentHandler (`lib/services/unified_intent_handler.dart`)

The core handler that processes all intents regardless of source.

**Key Features:**
- Validates intents against WorkflowGraph
- Tracks context (current node, book, topic, etc.)
- Returns different responses based on `IntentSource`
- Maintains workflow state

**Usage:**
```dart
final handler = UnifiedIntentHandler(
  workflowGraph: graph,
  bookService: BookService(), // optional, for testing
);

// Handle UI intent
final result = await handler.handleIntent(
  intent: 'listBook',
  source: IntentSource.ui,
);
// Returns: {action: 'listBook', data: {books: [...]}, requiresUI: true}

// Handle speech intent
final result = await handler.handleIntent(
  intent: 'listBook',
  source: IntentSource.speech,
);
// Returns: {action: 'speak', text: 'I found 5 books', requiresUI: false}
```

### 2. IntentBridgeService (`lib/services/intent_bridge_service.dart`)

Bridge between UI/controllers and foreground isolate.

**Usage:**
```dart
// From UI or controller
await IntentBridgeService.triggerUIIntent(
  intent: 'listBook',
);

// Result comes back through event bus
```

### 3. IntentSource Enum

Distinguishes between UI and speech sources:

```dart
enum IntentSource { ui, speech }
```

**Why it matters:**
- **UI**: Needs full data for display (lists, objects, IDs)
- **Speech**: Needs minimal text for TTS response

## Flow Examples

### Example 1: User Opens Books Screen

```dart
// 1. BooksController.onInit() triggers intent
await IntentBridgeService.triggerUIIntent(intent: 'listBook');

// 2. Foreground isolate receives and processes
UnifiedIntentHandler.handleIntent(
  intent: 'listBook',
  source: IntentSource.ui,
)

// 3. Returns full book data
{
  action: 'listBook',
  data: {books: [Book1, Book2, ...]},
  requiresUI: true
}

// 4. Event bus delivers to BooksController
eventBus.emit(AppEvent(AppEventType.voiceAction, result))

// 5. Controller updates books list
books.value = booksList;

// 6. UI automatically refreshes (Obx)
```

### Example 2: User Says "List Books"

```dart
// 1. Speech detected in VoiceForegroundTaskHandler
final text = "list my books";

// 2. LLM classifies intent
final response = await _intentClassifier.classify(text);
// {intent: 'listBook', slots: {}}

// 3. UnifiedIntentHandler processes with speech source
final result = await handler.handleIntent(
  intent: 'listBook',
  source: IntentSource.speech,
);

// 4. Returns TTS-friendly response
{
  action: 'speak',
  text: 'I found 5 books available',
  requiresUI: false
}

// 5. TTS speaks the response
await _ttsService.speak(result['text']);

// 6. Event bus also notifies UI (optional)
// UI can still update if needed
```

### Example 3: User Says "Select Book Harry Potter"

```dart
// 1. Speech: "select book harry potter"

// 2. LLM classifies
{intent: 'selectBook', slots: {bookName: 'Harry Potter'}}

// 3. UnifiedIntentHandler processes
- Validates 'selectBook' is allowed in current context
- Updates currentBookId
- Moves to 'book_context' node in workflow

// 4. Returns navigation action
{
  action: 'navigateToBook',
  data: {bookId: 'book_harry_potter', bookName: 'Harry Potter'},
  requiresUI: true
}

// 5. BooksScreen receives event and navigates
final book = controller.books.firstWhereOrNull(
  (b) => b.title.contains('Harry Potter')
);
openBook(book);
```

### Example 4: User Clicks Book Card

```dart
// 1. User taps on book card
onTap: () => openBook(book)

// 2. Direct navigation (no intent needed for simple actions)
Navigator.push(BookDetailsScreen(book: book))

// Alternative: Could also trigger intent for consistency
await IntentBridgeService.triggerUIIntent(
  intent: 'selectBook',
  slots: {'bookId': book.id},
);
```

## Implementation Guide

### Step 1: Update Controller

```dart
class BooksController extends GetxController {
  StreamSubscription? _voiceActionSub;
  
  @override
  void onInit() {
    super.onInit();
    _setupEventListeners();
    loadBooksViaIntent(); // Load via intent system
  }
  
  void _setupEventListeners() {
    _voiceActionSub = eventBus.stream
        .where((event) => event.type == AppEventType.voiceAction)
        .listen((event) {
      _handleVoiceAction(event.payload as Map<String, dynamic>);
    });
  }
  
  void _handleVoiceAction(Map<String, dynamic> action) {
    switch (action['action']) {
      case 'listBook':
        books.value = (action['data']['books'] as List)
            .map((b) => Book.fromJson(b))
            .toList();
        break;
    }
  }
  
  Future<void> loadBooksViaIntent() async {
    await IntentBridgeService.triggerUIIntent(intent: 'listBook');
  }
}
```

### Step 2: Update Screen

```dart
class _BooksScreenState extends State<BooksScreen> {
  StreamSubscription? _voiceActionSub;
  
  @override
  void initState() {
    super.initState();
    _voiceActionSub = eventBus.stream
        .where((e) => e.type == AppEventType.voiceAction)
        .listen((event) {
      _handleVoiceAction(event.payload as Map<String, dynamic>);
    });
  }
  
  void _handleVoiceAction(Map<String, dynamic> action) {
    switch (action['action']) {
      case 'navigateToBook':
        final bookId = action['data']['bookId'];
        final book = controller.books.firstWhereOrNull((b) => b.id == bookId);
        if (book != null) openBook(book);
        break;
    }
  }
}
```

## Benefits

### 1. **Simplified Architecture**
- Single handler for all intents
- No complex model wrappers
- Clear separation of concerns

### 2. **Flexible Source Handling**
- UI gets full data for display
- Speech gets minimal TTS text
- Same intent, different responses

### 3. **Maintains WorkflowGraph**
- Context tracking still works
- State transitions validated
- Flexible workflow design

### 4. **Better Performance**
- Less object creation
- Direct data passing
- Efficient event bus usage

### 5. **Easier Testing**
- Injectable dependencies
- Clear input/output
- Mockable services

### 6. **Consistent Pattern**
- Same flow for all features
- Predictable behavior
- Easy to extend

## Adding New Intents

### 1. Update WorkflowGraph (`assets/data/graph.json`)

```json
{
  "nodes": [
    {
      "id": "root",
      "allowed_intents": ["listBook", "newIntent"]
    }
  ],
  "edges": [
    {"from": "root", "intent": "newIntent", "to": "new_context"}
  ]
}
```

### 2. Add Handler in UnifiedIntentHandler

```dart
Future<Map<String, dynamic>> _handleNewIntent(IntentSource source) async {
  // Your logic here
  
  if (source == IntentSource.speech) {
    return {
      'action': 'speak',
      'text': 'TTS response',
      'requiresUI': false,
    };
  } else {
    return {
      'action': 'newAction',
      'data': {'key': 'value'},
      'requiresUI': true,
    };
  }
}
```

### 3. Handle in Controller/Screen

```dart
void _handleVoiceAction(Map<String, dynamic> action) {
  switch (action['action']) {
    case 'newAction':
      // Handle the new action
      break;
  }
}
```

## Troubleshooting

### Intent Not Working

1. Check WorkflowGraph allows intent in current context
2. Verify intent name matches exactly
3. Check event bus listeners are set up
4. Look for errors in foreground isolate logs

### Wrong Data Returned

1. Verify `IntentSource` is correct (ui vs speech)
2. Check handler returns correct format
3. Ensure controller handles the action type

### State Not Updating

1. Check event bus is emitting
2. Verify controller is listening
3. Ensure Obx is wrapping reactive widgets
4. Check if controller is properly initialized

## Migration from Old System

### Before (Complex)
```dart
// Multiple layers
LLMIntentClassifier → IntentSystemService → VoiceIntentDispatcher
→ VoiceActionEvent → Controller
```

### After (Simplified)
```dart
// Single unified handler
LLMIntentClassifier → UnifiedIntentHandler → Controller
```

### Migration Steps

1. Replace `IntentSystemService` with `UnifiedIntentHandler`
2. Update intent triggers to use `IntentBridgeService`
3. Change event listeners to handle Map instead of VoiceActionEvent
4. Update controllers to use new event format
5. Test both UI and speech flows

## Best Practices

1. **Always specify IntentSource** - UI vs speech matters
2. **Use event bus for async results** - Don't block UI
3. **Keep handlers simple** - One intent = one action
4. **Validate in WorkflowGraph** - Don't allow invalid transitions
5. **Test both sources** - UI and speech should both work
6. **Log intent flow** - Makes debugging easier
7. **Handle errors gracefully** - Return error actions, don't throw

## Summary

The Unified Intent System provides a clean, efficient way to handle both UI and speech intents through a single handler, while maintaining the flexibility of WorkflowGraph for context management. It reduces complexity, improves performance, and makes the codebase easier to maintain and extend.