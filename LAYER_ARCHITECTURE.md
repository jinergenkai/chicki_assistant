# Layer Architecture Explanation

> Clean Architecture trong Chicky Buddy App với FlashBook làm ví dụ

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│                    (UI + Controllers)                    │
├─────────────────────────────────────────────────────────┤
│                     BUSINESS LAYER                       │
│                       (Services)                         │
├─────────────────────────────────────────────────────────┤
│                       DATA LAYER                         │
│                   (Models + Storage)                     │
└─────────────────────────────────────────────────────────┘
```

### Principles
1. **Separation of Concerns**: Mỗi layer có responsibility riêng
2. **Dependency Rule**: Outer layers depend on inner layers
3. **Data Flow**: UI → Controller → Service → Data
4. **Single Responsibility**: Mỗi class chỉ làm 1 việc

---

## 📚 FlashBook Flow Example

### Scenario: User opens Books Screen và clicks vào một FlashBook

```
USER ACTION: Tap on "Travel English" book
         ↓
┌────────────────────────────────────────────────────────┐
│  LAYER 1: PRESENTATION (UI)                            │
│  File: lib/ui/screens/books_screen.dart                │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Widget: BooksScreen                                   │
│  - Displays grid of books                              │
│  - User taps on BookCard                               │
│                                                         │
│  Method: clickOpenBook(Book book)                      │
│  {                                                      │
│    if (book.type == BookType.flashBook) {              │
│      Navigator.push(BookDetailsScreen(book));          │
│    }                                                    │
│  }                                                      │
│                                                         │
└────────────────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────────────────┐
│  LAYER 1: PRESENTATION (Controller)                    │
│  File: lib/controllers/books_controller.dart           │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Class: BooksController extends GetxController         │
│  - Manages state (books list)                          │
│  - Observables: RxList<Book> books                     │
│  - Calls services, updates UI                          │
│                                                         │
│  Method: loadBooks()                                   │
│  {                                                      │
│    books.value = await bookService.loadAllBooks();     │
│  }                                                      │
│                                                         │
└────────────────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────────────────┐
│  LAYER 2: BUSINESS (Service)                           │
│  File: lib/services/book_service.dart                  │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Class: BookService                                    │
│  - Business logic cho books                            │
│  - No UI code, no direct Hive access (through box)    │
│  - Returns data to controllers                         │
│                                                         │
│  Method: loadAllBooks()                                │
│  {                                                      │
│    final static = await loadStaticBooks();             │
│    final custom = loadCustomBooks();                   │
│    return [...static, ...custom];                      │
│  }                                                      │
│                                                         │
│  Method: getBookVocabularies(String bookId)            │
│  {                                                      │
│    return vocabService.getVocabsByBookId(bookId);      │
│  }                                                      │
│                                                         │
└────────────────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────────────────┐
│  LAYER 3: DATA (Storage)                               │
│  File: lib/models/book.dart + Hive                     │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Class: Book extends HiveObject                        │
│  - Data model (pure data)                              │
│  - No business logic                                   │
│  - Hive annotations for persistence                    │
│                                                         │
│  Storage: Box<Book> _bookBox                           │
│  - Local database (Hive)                               │
│  - CRUD operations                                     │
│  - _bookBox.get(id)                                    │
│  - _bookBox.put(id, book)                              │
│  - _bookBox.values.toList()                            │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## 🔄 Complete FlashBook Flow

### 1. **User Opens Books Screen**

#### UI Layer (books_screen.dart)
```dart
class BooksScreen extends StatelessWidget {
  final controller = Get.find<BooksController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final books = controller.books;
      return GridView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(
            book: book,
            onTap: () => clickOpenBook(book),
          );
        },
      );
    });
  }

  void clickOpenBook(Book book) {
    // Route based on book type
    if (book.type == BookType.flashBook) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailsScreen(book: book),
        ),
      );
    }
  }
}
```

#### Controller Layer (books_controller.dart)
```dart
class BooksController extends GetxController {
  final BookService bookService;
  final RxList<Book> books = <Book>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final allBooks = await bookService.loadAllBooks();
      books.value = allBooks;
    } catch (e) {
      print('Error loading books: $e');
    }
  }
}
```

---

### 2. **Load Book Details**

#### UI Layer (book_details_screen.dart)
```dart
class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late VocabularyService vocabService;
  List<Vocabulary> vocabularies = [];

  @override
  void initState() {
    super.initState();
    vocabService = Get.find<VocabularyService>();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    final vocabs = await vocabService.getVocabsByBookId(widget.book.id);
    setState(() {
      vocabularies = vocabs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: Column(
        children: [
          // Stats
          Text('Total words: ${vocabularies.length}'),

          // Vocab list
          Expanded(
            child: ListView.builder(
              itemCount: vocabularies.length,
              itemBuilder: (context, index) {
                return VocabCard(vocab: vocabularies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

#### Service Layer (vocabulary_service.dart)
```dart
class VocabularyService {
  late Box<Vocabulary> _vocabBox;

  Future<void> init() async {
    _vocabBox = await Hive.openBox<Vocabulary>('vocabularyBox2');
  }

  // Business logic: Get vocabs filtered by bookId
  Future<List<Vocabulary>> getVocabsByBookId(String bookId) async {
    return _vocabBox.values
        .where((v) => v.bookId == bookId)
        .toList();
  }

  // Business logic: Add vocab with validation
  Future<void> addVocabulary(Vocabulary vocab) async {
    // Validate
    if (vocab.word.isEmpty) {
      throw Exception('Word cannot be empty');
    }

    // Save to database
    await _vocabBox.add(vocab);
  }

  // Business logic: Calculate learning stats
  Map<String, int> getBookStats(String bookId) {
    final vocabs = _vocabBox.values
        .where((v) => v.bookId == bookId)
        .toList();

    return {
      'total': vocabs.length,
      'mastered': vocabs.where((v) => v.masteryLevel >= 5).length,
      'learning': vocabs.where((v) => v.masteryLevel < 5).length,
    };
  }
}
```

#### Data Layer (vocabulary.dart)
```dart
@HiveType(typeId: 100)
class Vocabulary extends HiveObject {
  @HiveField(0)
  String word;

  @HiveField(1)
  String meaning;

  @HiveField(2)
  String? exampleSentence;

  @HiveField(3)
  String bookId; // Foreign key to Book

  @HiveField(4)
  int masteryLevel; // 0-5 for SRS

  @HiveField(5)
  DateTime? nextReviewDate;

  // No business logic here, just data
  Vocabulary({
    required this.word,
    required this.meaning,
    required this.bookId,
    this.exampleSentence,
    this.masteryLevel = 0,
    this.nextReviewDate,
  });
}
```

---

### 3. **User Starts Learning Session**

#### UI Layer (book_details_screen.dart)
```dart
void _startLearning() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FlashCardScreen(book: widget.book),
    ),
  );
}
```

#### UI Layer (flash_card_screen.dart)
```dart
class FlashCardScreen extends StatefulWidget {
  final Book book;
  const FlashCardScreen({required this.book});

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  late VocabularyService vocabService;
  List<Vocabulary> vocabularies = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    vocabService = Get.find<VocabularyService>();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    final vocabs = await vocabService.getVocabsByBookId(widget.book.id);
    setState(() {
      vocabularies = vocabs;
    });
  }

  void _onAnswerCorrect() async {
    final vocab = vocabularies[currentIndex];

    // Call service to update mastery
    await vocabService.updateMastery(vocab, isCorrect: true);

    // Move to next card
    setState(() {
      if (currentIndex < vocabularies.length - 1) {
        currentIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (vocabularies.isEmpty) {
      return CircularProgressIndicator();
    }

    final vocab = vocabularies[currentIndex];

    return Scaffold(
      body: FlashCard(
        word: vocab.word,
        meaning: vocab.meaning,
        onCorrect: _onAnswerCorrect,
        onIncorrect: _onAnswerIncorrect,
      ),
    );
  }
}
```

#### Service Layer (vocabulary_service.dart)
```dart
// Business logic: Update vocabulary mastery (SRS algorithm)
Future<void> updateMastery(Vocabulary vocab, {required bool isCorrect}) async {
  if (isCorrect) {
    // SRS algorithm
    vocab.masteryLevel = (vocab.masteryLevel + 1).clamp(0, 5);

    // Calculate next review date
    final intervals = [1, 3, 7, 14, 30]; // days
    if (vocab.masteryLevel < intervals.length) {
      vocab.nextReviewDate = DateTime.now()
          .add(Duration(days: intervals[vocab.masteryLevel]));
    }
  } else {
    // Wrong answer - reset or decrease
    vocab.masteryLevel = (vocab.masteryLevel - 1).clamp(0, 5);
    vocab.nextReviewDate = DateTime.now().add(Duration(hours: 4));
  }

  // Save to database
  await vocab.save();
}
```

---

## 📊 Layer Responsibilities

### ✅ Presentation Layer (UI + Controllers)
**What it does:**
- Display data to user
- Handle user interactions
- Manage UI state
- Call services

**What it DOESN'T do:**
- ❌ Direct database access
- ❌ Business logic
- ❌ Data transformation

**Files:**
- `lib/ui/screens/*.dart`
- `lib/ui/widgets/*.dart`
- `lib/controllers/*.dart`

---

### ✅ Business Layer (Services)
**What it does:**
- Business logic
- Data transformation
- Validation
- Orchestrate data operations
- Calculate statistics

**What it DOESN'T do:**
- ❌ UI code (no Widgets, no BuildContext)
- ❌ Direct Hive box operations (use through models)

**Files:**
- `lib/services/book_service.dart`
- `lib/services/vocabulary_service.dart`
- `lib/services/journal_service.dart`
- `lib/services/story_service.dart`

---

### ✅ Data Layer (Models + Storage)
**What it does:**
- Define data structure
- Persistence (Hive)
- Serialization (JSON)
- CRUD operations on database

**What it DOESN'T do:**
- ❌ Business logic
- ❌ UI logic
- ❌ Complex calculations

**Files:**
- `lib/models/*.dart`
- Hive boxes

---

## 🔄 Data Flow Diagram

```
┌──────────┐
│   User   │
└────┬─────┘
     │ tap/action
     ▼
┌──────────────────────────────────┐
│  UI (Widget)                     │
│  - Displays data                 │
│  - Captures user input           │
└────┬─────────────────────────────┘
     │ calls method
     ▼
┌──────────────────────────────────┐
│  Controller (GetX)               │
│  - Manages state                 │
│  - Observables (Rx)              │
└────┬─────────────────────────────┘
     │ calls service
     ▼
┌──────────────────────────────────┐
│  Service (Business Logic)        │
│  - Validates data                │
│  - Processes business rules      │
│  - Calls data operations         │
└────┬─────────────────────────────┘
     │ CRUD operations
     ▼
┌──────────────────────────────────┐
│  Models + Hive (Data Storage)    │
│  - Saves to database             │
│  - Returns data                  │
└────┬─────────────────────────────┘
     │ returns data
     ▼
   (back up through layers)
     ▼
┌──────────────────────────────────┐
│  UI updates (Obx rebuilds)       │
│  - Displays new data             │
└──────────────────────────────────┘
```

---

## 🎯 Real Example: Add New Vocabulary

### Step by Step Flow

```dart
// 1. UI: User taps "Add Vocab" button
void _showAddVocabDialog() {
  showDialog(
    context: context,
    builder: (_) => AddVocabularyDialog(
      bookId: widget.book.id,
      onAdd: (word, meaning) async {
        // 2. Call service to add vocab
        await vocabService.addVocabulary(
          Vocabulary(
            word: word,
            meaning: meaning,
            bookId: widget.book.id,
          ),
        );

        // 3. Reload list
        await _loadVocabularies();
      },
    ),
  );
}

// Service: Validation + Save
class VocabularyService {
  Future<void> addVocabulary(Vocabulary vocab) async {
    // Business logic: Validate
    if (vocab.word.trim().isEmpty) {
      throw Exception('Word cannot be empty');
    }

    // Business logic: Check duplicates
    final existing = _vocabBox.values
        .where((v) => v.word == vocab.word && v.bookId == vocab.bookId)
        .toList();

    if (existing.isNotEmpty) {
      throw Exception('Word already exists in this book');
    }

    // Business logic: Set defaults
    vocab.createdAt = DateTime.now();
    vocab.masteryLevel = 0;

    // Data: Save to Hive
    await _vocabBox.add(vocab);
  }
}
```

---

## ✅ Best Practices

### 1. **Keep UI Dumb**
```dart
// ❌ BAD: UI has business logic
void _addVocab() {
  if (word.isEmpty) {
    showError('Word empty');
    return;
  }
  final vocab = Vocabulary(...);
  _vocabBox.add(vocab); // Direct database access!
}

// ✅ GOOD: UI calls service
void _addVocab() async {
  try {
    await vocabService.addVocabulary(word, meaning);
    _showSuccess();
  } catch (e) {
    _showError(e.message);
  }
}
```

### 2. **Services Don't Know About UI**
```dart
// ❌ BAD: Service imports Flutter
import 'package:flutter/material.dart';

void showError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}

// ✅ GOOD: Service throws exceptions
void addVocabulary(Vocabulary vocab) {
  if (vocab.word.isEmpty) {
    throw ValidationException('Word cannot be empty');
  }
  // ...
}
```

### 3. **Models Are Pure Data**
```dart
// ❌ BAD: Model has business logic
class Vocabulary {
  String word;
  int masteryLevel;

  void updateMastery(bool correct) {
    if (correct) masteryLevel++;
    else masteryLevel--;
  }
}

// ✅ GOOD: Service has business logic
class VocabularyService {
  void updateMastery(Vocabulary vocab, bool correct) {
    if (correct) {
      vocab.masteryLevel = (vocab.masteryLevel + 1).clamp(0, 5);
    }
    vocab.save();
  }
}
```

---

## 🎓 Summary

### Why This Architecture?

1. **Testability**: Dễ test từng layer riêng
2. **Maintainability**: Dễ maintain, bug ít
3. **Scalability**: Dễ thêm features mới
4. **Reusability**: Services có thể dùng ở nhiều UI
5. **Clear Responsibilities**: Mỗi layer biết rõ việc của mình

### FlashBook Flow Summary

```
User taps book
  → UI shows book details
  → Controller calls BookService
  → BookService gets data from Hive
  → Data flows back up
  → UI displays with Obx

User starts learning
  → UI shows flashcards
  → User answers correct/wrong
  → Service updates mastery (SRS algorithm)
  → Service saves to Hive
  → UI shows next card
```

---

*Ready to implement với kiến trúc này?* 🚀
