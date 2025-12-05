# Book Types Architecture Plan

> Design cho 3 types chính: FlashBook, Journal, Story + JSON Import Feature

---

## 📊 Current State Analysis

### Current Book Model
```dart
class Book {
  String id;
  String title;
  String description;
  BookSource source; // statics, userCreated, imported
  // ... other fields
}
```

### Current Storage
- **Static books**: Loaded từ `assets/vocab/books.json` → Save to Hive
- **Custom books**: User created → Save to Hive
- **Imported books**: (chưa implement) → Sẽ save to Hive

### Issues
❌ Không có BookType để distinguish FlashBook/Journal/Story
❌ Dễ nhầm lẫn giữa JSON source và Hive storage
❌ Chưa có feature import JSON book từ friends

---

## 🎯 Proposed Architecture

### 1. Add BookType Enum

```dart
@HiveType(typeId: 202)
enum BookType {
  @HiveField(0)
  flashBook,    // Vocabulary learning với flashcards

  @HiveField(1)
  journal,      // Diary/Journal entries

  @HiveField(2)
  story,        // Reading stories/articles
}
```

### 2. Update Book Model

```dart
@HiveType(typeId: 200)
@JsonSerializable()
class Book extends HiveObject {
  // ... existing fields

  @HiveField(17)
  @JsonKey(defaultValue: BookType.flashBook)
  BookType type; // NEW: Book type

  @HiveField(18)
  Map<String, dynamic>? typeConfig; // NEW: Type-specific config

  // Constructor update
  Book({
    // ... existing params
    this.type = BookType.flashBook,
    this.typeConfig,
  });
}
```

### 3. Type-Specific Configurations

#### FlashBook Config
```dart
{
  'srsEnabled': true,
  'autoPlayAudio': true,
  'showExamples': true,
  'difficulty': 'beginner', // beginner, intermediate, advanced
  'learningMode': 'standard', // standard, intensive, review
}
```

#### Journal Config
```dart
{
  'isPrivate': true,
  'allowComments': false,
  'template': 'free-form', // free-form, gratitude, daily-log
  'promptsEnabled': true,
  'dailyReminder': '20:00',
}
```

#### Story Config
```dart
{
  'genre': 'fiction', // fiction, non-fiction, fantasy, etc.
  'readingLevel': 'intermediate',
  'chapterCount': 10,
  'estimatedReadTime': 45, // minutes
  'hasAudio': false,
}
```

---

## 📚 Data Structure for Each Type

### FlashBook (Vocabulary Learning)
```dart
// Existing structure works well
- Book (metadata)
- Vocabulary[] (words linked to bookId)
- Learning progress (SRS system)
```

**Storage**:
- Book → `bookBox2`
- Vocabulary → `vocabularyBox2`
- Progress → User model

### Journal (Diary)
```dart
// New structure needed
- Book (metadata + journal config)
- JournalEntry[] (entries linked to bookId)
  - id: String
  - bookId: String
  - date: DateTime
  - title: String?
  - content: String (rich text/markdown)
  - mood: String? (happy, sad, excited, etc.)
  - tags: List<String>
  - images: List<String>? (local paths)
  - createdAt: DateTime
  - updatedAt: DateTime
```

**Storage**:
- Book → `bookBox2`
- JournalEntry → `journalEntryBox` (NEW)

### Story (Reading)
```dart
// New structure needed
- Book (metadata + story config)
- StoryChapter[] (chapters linked to bookId)
  - id: String
  - bookId: String
  - chapterNumber: int
  - title: String
  - content: String (markdown/HTML)
  - wordCount: int
  - readingProgress: double (0.0 - 1.0)
  - lastReadAt: DateTime?
  - notes: List<StoryNote>? (annotations)
```

**Storage**:
- Book → `bookBox2`
- StoryChapter → `storyChapterBox` (NEW)
- StoryNote → Embedded in chapter or separate box

---

## 🔄 JSON Import/Export Feature

### Concept
**"Single Source of Truth = Hive"**
- JSON chỉ là format để share/backup
- Khi import JSON → Parse → Save to Hive
- Khi export → Read from Hive → Generate JSON

### JSON Structure

#### FlashBook JSON
```json
{
  "version": "1.0",
  "type": "flashBook",
  "book": {
    "id": "book_123",
    "title": "Travel English",
    "description": "Essential phrases...",
    "source": "imported",
    "typeConfig": {
      "srsEnabled": true,
      "difficulty": "beginner"
    }
  },
  "vocabularies": [
    {
      "word": "hello",
      "meaning": "xin chào",
      "example": "Hello, how are you?"
    }
  ],
  "metadata": {
    "exportedAt": "2025-01-04T10:00:00Z",
    "exportedBy": "user_456",
    "checksum": "sha256_hash"
  }
}
```

#### Journal JSON
```json
{
  "version": "1.0",
  "type": "journal",
  "book": {
    "id": "journal_456",
    "title": "My 2025 Journal",
    "typeConfig": {
      "isPrivate": true,
      "template": "gratitude"
    }
  },
  "entries": [
    {
      "id": "entry_1",
      "date": "2025-01-01",
      "title": "New Year",
      "content": "Today was amazing...",
      "mood": "happy",
      "tags": ["gratitude", "reflection"]
    }
  ]
}
```

#### Story JSON
```json
{
  "version": "1.0",
  "type": "story",
  "book": {
    "id": "story_789",
    "title": "The Adventure",
    "typeConfig": {
      "genre": "fiction",
      "chapterCount": 5
    }
  },
  "chapters": [
    {
      "chapterNumber": 1,
      "title": "Chapter 1: Beginning",
      "content": "Once upon a time...",
      "wordCount": 1500
    }
  ]
}
```

### Import Flow

```
1. User taps "Import Book" button
   ↓
2. Choose source:
   - From JSON file (local)
   - From share code (QR/link)
   - From URL (cloud)
   ↓
3. Parse JSON
   - Validate version
   - Check type (flashBook/journal/story)
   - Verify checksum
   ↓
4. Save to Hive
   - Book → bookBox2
   - Content → respective box
   - Set source = BookSource.imported
   ↓
5. Show success + Navigate to book
```

### Export Flow

```
1. User taps "Share Book" on book details
   ↓
2. Select export format:
   - JSON file
   - QR code
   - Share link
   ↓
3. Read from Hive
   - Get book metadata
   - Get all content (vocabs/entries/chapters)
   ↓
4. Generate JSON
   - Add metadata (timestamp, author, checksum)
   - Compress if large
   ↓
5. Share
   - Save to file
   - Generate QR code
   - Create shareable link
```

---

## 🎨 UI Differences by Type

### FlashBook UI
- **Icon**: 🎴 Cards icon
- **Color**: Blue gradient
- **Card view**: Shows vocab count, progress
- **Details screen**:
  - Start Learning button
  - Vocab list
  - Stats (mastered, learning, etc.)

### Journal UI
- **Icon**: 📔 Book icon
- **Color**: Purple/Pink gradient
- **Card view**: Shows entry count, last entry date
- **Details screen**:
  - New Entry button
  - Calendar view
  - Entry list (by date)
  - Mood chart

### Story UI
- **Icon**: 📖 Open book icon
- **Color**: Orange/Amber gradient
- **Card view**: Shows chapter count, reading progress
- **Details screen**:
  - Continue Reading button
  - Chapter list
  - Reading progress bar
  - Bookmarks

---

## 📁 File Structure

### New Files to Create

```
lib/
├── models/
│   ├── book.dart (UPDATE: add BookType)
│   ├── journal_entry.dart (NEW)
│   └── story_chapter.dart (NEW)
├── services/
│   ├── book_service.dart (UPDATE: add import/export)
│   ├── journal_service.dart (NEW)
│   └── story_service.dart (NEW)
├── ui/
│   ├── screens/
│   │   ├── journal/
│   │   │   ├── journal_list_screen.dart
│   │   │   ├── journal_entry_screen.dart
│   │   │   └── journal_calendar_screen.dart
│   │   └── story/
│   │       ├── story_list_screen.dart
│   │       ├── story_reader_screen.dart
│   │       └── story_chapter_list_screen.dart
│   └── widgets/
│       ├── book_card.dart (UPDATE: support all types)
│       ├── journal_entry_card.dart (NEW)
│       └── story_chapter_card.dart (NEW)
```

---

## 🔧 Implementation Steps

### Phase 1: Core Architecture (Week 1)
1. ✅ Add BookType enum
2. ✅ Update Book model with type and typeConfig
3. ✅ Create JournalEntry and StoryChapter models
4. ✅ Generate Hive adapters
5. ✅ Update existing books to have type = flashBook

### Phase 2: Services (Week 1-2)
1. ✅ Create JournalService (CRUD for entries)
2. ✅ Create StoryService (CRUD for chapters)
3. ✅ Update BookService with import/export methods
4. ✅ Add JSON parsing utilities

### Phase 3: UI Updates (Week 2)
1. ✅ Update BookCard to show different UI by type
2. ✅ Add type selector in Create Book dialog
3. ✅ Update BooksScreen with type filters
4. ✅ Update BookDetailsScreen to route by type

### Phase 4: Journal Feature (Week 3)
1. ✅ Journal list screen
2. ✅ Journal entry editor (rich text)
3. ✅ Calendar view
4. ✅ Mood tracking

### Phase 5: Story Feature (Week 3-4)
1. ✅ Story reader screen
2. ✅ Chapter navigation
3. ✅ Progress tracking
4. ✅ Bookmarks and notes

### Phase 6: Import/Export (Week 4)
1. ✅ Export to JSON
2. ✅ Import from JSON
3. ✅ QR code generation
4. ✅ Share links

---

## ✅ Advantages of This Design

### 1. Clear Separation
✅ BookType makes it crystal clear what each book is for
✅ No confusion between JSON source and storage
✅ Type-specific configs allow flexibility

### 2. Single Source of Truth
✅ Hive is the only source of truth
✅ JSON is just import/export format
✅ No sync issues between JSON and Hive

### 3. Extensibility
✅ Easy to add new book types (e.g., Quiz, Podcast)
✅ Type-specific config allows customization
✅ Import/export works for all types

### 4. User-Friendly
✅ Users can import books from friends easily
✅ Books are saved locally, always accessible
✅ Can share books via JSON/QR/link

---

## 🎯 Migration Strategy

### For Existing Books
```dart
// One-time migration on app update
Future<void> migrateExistingBooks() async {
  final books = bookBox.values;
  for (final book in books) {
    if (book.type == null) {
      // Assume all existing books are flashBooks
      book.type = BookType.flashBook;
      book.typeConfig = {
        'srsEnabled': true,
        'autoPlayAudio': true,
      };
      await book.save();
    }
  }
}
```

---

## 📖 Example Usage

### Creating a FlashBook
```dart
final book = Book(
  id: uuid.v4(),
  title: 'Business English',
  description: 'Essential business phrases',
  type: BookType.flashBook,
  source: BookSource.userCreated,
  typeConfig: {
    'srsEnabled': true,
    'difficulty': 'intermediate',
  },
);
await bookService.addCustomBook(book);
```

### Creating a Journal
```dart
final journal = Book(
  id: uuid.v4(),
  title: 'My Daily Journal',
  description: 'Personal thoughts and reflections',
  type: BookType.journal,
  source: BookSource.userCreated,
  typeConfig: {
    'isPrivate': true,
    'template': 'gratitude',
  },
);
await bookService.addCustomBook(journal);
```

### Importing from JSON
```dart
final jsonString = await loadJsonFile();
final bookData = await bookService.importFromJson(jsonString);
// Automatically saved to Hive
// bookData.source == BookSource.imported
```

---

## 🤔 Decisions & Rationale

### Q: Tại sao dùng typeConfig thay vì separate models?
**A**: Flexibility! Mỗi type có thể có configs khác nhau mà không cần tạo nhiều models. Dễ extend sau này.

### Q: Tại sao không dùng JSON làm primary storage?
**A**:
- Hive nhanh hơn (local database)
- JSON chỉ tốt cho import/export
- Hive hỗ trợ relationships tốt hơn
- Performance better cho large datasets

### Q: Làm sao distinguish static books và imported books?
**A**: Dùng `BookSource` enum:
- `statics`: Từ assets (built-in)
- `userCreated`: User tự tạo
- `imported`: Download/import từ friends

### Q: Journal và Story có cần SRS không?
**A**: Không! Chỉ FlashBook cần SRS. Đó là lý do cần BookType để distinguish.

---

## 📝 Next Steps

1. ✅ Review architecture với team
2. ⏳ Implement Phase 1 (models + enum)
3. ⏳ Test migration với existing data
4. ⏳ Implement Phase 2 (services)
5. ⏳ Start UI development

---

*Updated: 2025-01-04*
*Author: AI Architecture Assistant*
