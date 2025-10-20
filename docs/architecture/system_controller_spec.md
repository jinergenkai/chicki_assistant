# SystemController Specification

## Mục tiêu
- Quản lý state toàn cục cho voice workflow
- Cung cấp API cho UI và các service truy xuất state
- Xử lý VoiceActionEvent và cập nhật VoiceStateContext
- Phát event stateChanged cho UI và debug

## API chính

```dart
class SystemController extends GetxController {
  final voiceState = VoiceStateContext(currentScreen: 'idle').obs;
  final currentBook = Rxn<Book>();
  final currentTopic = Rxn<Topic>();
  final currentCards = <VocabCard>[].obs;

  Future<void> handleVoiceAction(VoiceActionEvent event);
  Future<void> _loadBook(String bookId);
  Future<void> _loadTopic(String topicId);
  Future<void> _loadCards(String topicId);

  Book? get book;
  Topic? get topic;
  List<VocabCard> get cards;
}
```

## Event Flow

- Nhận VoiceActionEvent từ IntentDispatcher hoặc Background Isolate
- Thực thi action (load data, update state)
- Cập nhật voiceState
- Emit AppEvent(stateChanged, voiceState.value)
- UI chỉ listen voiceState và load data từ SystemController

## State Tracking

- Lưu history cho undo/redo
- Persist state khi cần (shared_preferences, local db)
- Phát event khi state thay đổi

## Error Handling

- Nếu action lỗi, emit AppEvent(stateError, error)
- Log chi tiết cho debug

## Extension

- Có thể mở rộng cho các loại state khác (quiz, review, v.v.)
- Cho phép inject các repository/data source
