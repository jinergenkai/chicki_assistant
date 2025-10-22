# Files to Archive

These files are part of the old complex intent system and can be moved to `_archive` folder since they've been replaced by the unified intent system.

## Files to Archive

### 1. Old Intent System Service
- **File**: `lib/services/intent/intent_system_service.dart`
- **Reason**: Replaced by `UnifiedIntentHandler`
- **Size**: ~58 lines
- **Status**: No longer used

### 2. Old Voice Intent Dispatcher
- **File**: `lib/voice/dispatcher/voice_intent_dispatcher.dart`
- **Reason**: Logic merged into `UnifiedIntentHandler`
- **Size**: ~102 lines
- **Status**: No longer used

### 3. Old Intent Graph (if not used elsewhere)
- **File**: `lib/voice/dispatcher/intent_graph.dart`
- **Reason**: Replaced by WorkflowGraph usage in UnifiedIntentHandler
- **Status**: Check if used elsewhere before archiving

### 4. Complex Model Wrappers
- **File**: `lib/voice/models/voice_action_event.dart`
- **Reason**: Replaced by simple Map<String, dynamic> in unified system
- **Size**: ~55 lines
- **Status**: No longer used (check BooksScreen first)

- **File**: `lib/voice/models/voice_intent_payload.dart`
- **Reason**: Replaced by simple Map<String, dynamic> in unified system
- **Size**: ~62 lines
- **Status**: No longer used

- **File**: `lib/voice/models/voice_state_context.dart`
- **Reason**: State now tracked directly in UnifiedIntentHandler
- **Size**: ~102 lines
- **Status**: No longer used

### 5. Old Intent Handlers (if not used)
- **File**: `lib/voice/handlers/intent_handler.dart`
- **File**: `lib/voice/handlers/next_vocab_handler.dart`
- **File**: `lib/voice/handlers/read_aloud_handler.dart`
- **File**: `lib/voice/handlers/select_book_handler.dart`
- **File**: `lib/voice/handlers/select_topic_handler.dart`
- **Reason**: Logic now in UnifiedIntentHandler methods
- **Status**: Check if used elsewhere before archiving

### 6. Old Isolate System (if not used)
- **File**: `lib/voice/core/voice_isolate_channel.dart`
- **File**: `lib/voice/core/voice_isolate_entry.dart`
- **File**: `lib/voice/core/voice_isolate_manager.dart`
- **File**: `lib/voice/core/voice_isolate_worker.dart`
- **Reason**: Now using FlutterForegroundTask directly
- **Status**: Check if used elsewhere before archiving

## Files to Keep

### Keep - Still Used
- `lib/voice/graph/workflow_graph.dart` - Used by UnifiedIntentHandler
- `lib/voice/graph/intent_node.dart` - Used by WorkflowGraph
- `lib/voice/graph/intent_edge.dart` - Used by WorkflowGraph
- `lib/voice/graph/workflow_state.dart` - May be used elsewhere
- `lib/voice/dispatcher/intent_classifier_service.dart` - Base class for LLMIntentClassifierService
- `lib/voice/simulator/intent_simulator.dart` - Testing tool

### New Files - Core System
- `lib/services/unified_intent_handler.dart` - New unified handler
- `lib/core/isolate_message.dart` - New unified message format
- `lib/services/intent_bridge_service.dart` - Updated bridge service

## Recommended Archive Structure

```
_archive/
├── old_intent_system/
│   ├── services/
│   │   └── intent_system_service.dart
│   ├── dispatcher/
│   │   ├── voice_intent_dispatcher.dart
│   │   └── intent_graph.dart
│   ├── models/
│   │   ├── voice_action_event.dart
│   │   ├── voice_intent_payload.dart
│   │   └── voice_state_context.dart
│   ├── handlers/
│   │   ├── intent_handler.dart
│   │   ├── next_vocab_handler.dart
│   │   ├── read_aloud_handler.dart
│   │   ├── select_book_handler.dart
│   │   └── select_topic_handler.dart
│   └── isolate/
│       ├── voice_isolate_channel.dart
│       ├── voice_isolate_entry.dart
│       ├── voice_isolate_manager.dart
│       └── voice_isolate_worker.dart
└── README.md (explaining why archived and migration date)
```

## Estimated Code Reduction

- **Old Intent System**: ~58 lines
- **Old Dispatcher**: ~102 lines
- **Old Models**: ~219 lines (55 + 62 + 102)
- **Old Handlers**: ~250 lines (estimated)
- **Old Isolate System**: ~400 lines (estimated)

**Total Reduction**: ~1,029 lines of complex code

**New Unified System**: ~267 lines (UnifiedIntentHandler) + ~207 lines (IsolateMessage) = ~474 lines

**Net Reduction**: ~555 lines (54% reduction)

## Before Archiving - Checklist

1. ✅ Search entire codebase for imports of these files
2. ✅ Check if any screens still use VoiceActionEvent
3. ✅ Verify all tests pass without these files
4. ✅ Check if any other services depend on these files
5. ✅ Create backup before moving to archive
6. ✅ Update any documentation referencing old system

## Migration Command

```bash
# Create archive directory
mkdir -p _archive/old_intent_system/{services,dispatcher,models,handlers,isolate}

# Move files (after verification)
# Example:
# mv lib/services/intent/intent_system_service.dart _archive/old_intent_system/services/
# mv lib/voice/dispatcher/voice_intent_dispatcher.dart _archive/old_intent_system/dispatcher/
# etc.
```

## Notes

- Keep this document for reference
- Archive files should be kept for at least 3 months before deletion
- If any issues arise, files can be restored from archive
- Consider creating a git tag before archiving: `git tag -a v1.0-pre-unified-intent -m "Before unified intent system"`