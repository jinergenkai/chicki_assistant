@echo off
REM Windows batch script to archive old intent system files
REM Run this from the project root directory

echo Creating archive directory structure...
mkdir _archive\old_intent_system\services 2>nul
mkdir _archive\old_intent_system\dispatcher 2>nul
mkdir _archive\old_intent_system\models 2>nul
mkdir _archive\old_intent_system\handlers 2>nul
mkdir _archive\old_intent_system\isolate 2>nul

echo.
echo Moving old intent system files to archive...

REM Move old intent system service
if exist lib\services\intent\intent_system_service.dart (
    move lib\services\intent\intent_system_service.dart _archive\old_intent_system\services\
    echo [OK] Moved intent_system_service.dart
) else (
    echo [SKIP] intent_system_service.dart not found
)

REM Move old dispatcher files
if exist lib\voice\dispatcher\voice_intent_dispatcher.dart (
    move lib\voice\dispatcher\voice_intent_dispatcher.dart _archive\old_intent_system\dispatcher\
    echo [OK] Moved voice_intent_dispatcher.dart
) else (
    echo [SKIP] voice_intent_dispatcher.dart not found
)

if exist lib\voice\dispatcher\intent_graph.dart (
    move lib\voice\dispatcher\intent_graph.dart _archive\old_intent_system\dispatcher\
    echo [OK] Moved intent_graph.dart
) else (
    echo [SKIP] intent_graph.dart not found
)

REM Move old model files
if exist lib\voice\models\voice_action_event.dart (
    move lib\voice\models\voice_action_event.dart _archive\old_intent_system\models\
    echo [OK] Moved voice_action_event.dart
) else (
    echo [SKIP] voice_action_event.dart not found
)

if exist lib\voice\models\voice_intent_payload.dart (
    move lib\voice\models\voice_intent_payload.dart _archive\old_intent_system\models\
    echo [OK] Moved voice_intent_payload.dart
) else (
    echo [SKIP] voice_intent_payload.dart not found
)

if exist lib\voice\models\voice_state_context.dart (
    move lib\voice\models\voice_state_context.dart _archive\old_intent_system\models\
    echo [OK] Moved voice_state_context.dart
) else (
    echo [SKIP] voice_state_context.dart not found
)

REM Move old handler files
if exist lib\voice\handlers\intent_handler.dart (
    move lib\voice\handlers\intent_handler.dart _archive\old_intent_system\handlers\
    echo [OK] Moved intent_handler.dart
) else (
    echo [SKIP] intent_handler.dart not found
)

if exist lib\voice\handlers\next_vocab_handler.dart (
    move lib\voice\handlers\next_vocab_handler.dart _archive\old_intent_system\handlers\
    echo [OK] Moved next_vocab_handler.dart
) else (
    echo [SKIP] next_vocab_handler.dart not found
)

if exist lib\voice\handlers\read_aloud_handler.dart (
    move lib\voice\handlers\read_aloud_handler.dart _archive\old_intent_system\handlers\
    echo [OK] Moved read_aloud_handler.dart
) else (
    echo [SKIP] read_aloud_handler.dart not found
)

if exist lib\voice\handlers\select_book_handler.dart (
    move lib\voice\handlers\select_book_handler.dart _archive\old_intent_system\handlers\
    echo [OK] Moved select_book_handler.dart
) else (
    echo [SKIP] select_book_handler.dart not found
)

if exist lib\voice\handlers\select_topic_handler.dart (
    move lib\voice\handlers\select_topic_handler.dart _archive\old_intent_system\handlers\
    echo [OK] Moved select_topic_handler.dart
) else (
    echo [SKIP] select_topic_handler.dart not found
)

REM Move old isolate files
if exist lib\voice\core\voice_isolate_channel.dart (
    move lib\voice\core\voice_isolate_channel.dart _archive\old_intent_system\isolate\
    echo [OK] Moved voice_isolate_channel.dart
) else (
    echo [SKIP] voice_isolate_channel.dart not found
)

if exist lib\voice\core\voice_isolate_entry.dart (
    move lib\voice\core\voice_isolate_entry.dart _archive\old_intent_system\isolate\
    echo [OK] Moved voice_isolate_entry.dart
) else (
    echo [SKIP] voice_isolate_entry.dart not found
)

if exist lib\voice\core\voice_isolate_manager.dart (
    move lib\voice\core\voice_isolate_manager.dart _archive\old_intent_system\isolate\
    echo [OK] Moved voice_isolate_manager.dart
) else (
    echo [SKIP] voice_isolate_manager.dart not found
)

if exist lib\voice\core\voice_isolate_worker.dart (
    move lib\voice\core\voice_isolate_worker.dart _archive\old_intent_system\isolate\
    echo [OK] Moved voice_isolate_worker.dart
) else (
    echo [SKIP] voice_isolate_worker.dart not found
)

REM Create README in archive
echo Creating archive README...
(
echo # Archived Old Intent System
echo.
echo **Archive Date:** %date% %time%
echo **Reason:** Replaced by Unified Intent System
echo.
echo ## What was archived
echo.
echo This directory contains the old complex intent system that was replaced
echo by the new unified intent system. The old system had multiple layers:
echo.
echo - IntentSystemService
echo - VoiceIntentDispatcher  
echo - Complex model wrappers ^(VoiceActionEvent, VoiceIntentPayload, VoiceStateContext^)
echo - Separate intent handlers
echo - Custom isolate management
echo.
echo ## New System
echo.
echo The new unified system simplifies this to:
echo.
echo - UnifiedIntentHandler ^(single handler for all intents^)
echo - IsolateMessage ^(unified message format^)
echo - Direct FlutterForegroundTask usage
echo.
echo ## Code Reduction
echo.
echo - Old system: ~1,029 lines
echo - New system: ~474 lines
echo - Reduction: ~555 lines ^(54%% reduction^)
echo.
echo ## Files can be restored if needed
echo.
echo These files are kept for reference and can be restored if any issues arise.
echo Consider deleting after 3 months if no issues are found.
echo.
echo ## Documentation
echo.
echo See docs/unified_intent_system.md for the new system documentation.
echo See docs/files_to_archive.md for the full list of archived files.
) > _archive\old_intent_system\README.md

echo.
echo ========================================
echo Archive complete!
echo ========================================
echo.
echo Files have been moved to: _archive\old_intent_system\
echo.
echo Next steps:
echo 1. Run 'flutter pub get' to update dependencies
echo 2. Run 'flutter analyze' to check for any issues
echo 3. Test the application thoroughly
echo 4. If everything works, commit the changes
echo.
echo To restore files if needed, simply move them back from _archive\
echo.
pause