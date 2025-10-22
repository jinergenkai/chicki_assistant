# Archived Old Intent System

**Archive Date:** Wed 10/22/2025 16:24:25.38
**Reason:** Replaced by Unified Intent System

## What was archived

This directory contains the old complex intent system that was replaced
by the new unified intent system. The old system had multiple layers:

- IntentSystemService
- VoiceIntentDispatcher  
- Complex model wrappers (VoiceActionEvent, VoiceIntentPayload, VoiceStateContext)
- Separate intent handlers
- Custom isolate management

## New System

The new unified system simplifies this to:

- UnifiedIntentHandler (single handler for all intents)
- IsolateMessage (unified message format)
- Direct FlutterForegroundTask usage

## Code Reduction

- Old system: ~1,029 lines
- New system: ~474 lines
- Reduction: ~555 lines (54% reduction)

## Files can be restored if needed

These files are kept for reference and can be restored if any issues arise.
Consider deleting after 3 months if no issues are found.

## Documentation

See docs/unified_intent_system.md for the new system documentation.
See docs/files_to_archive.md for the full list of archived files.
