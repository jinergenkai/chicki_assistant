# 📚 Book Types Quick Start Guide

## 🎯 Overview

Chicky Buddy hiện hỗ trợ 3 loại sách:
1. **FlashBook** - Học từ vựng với flashcards
2. **Journal** - Viết nhật ký với mood tracking
3. **Story** - Đọc truyện với progress tracking

---

## 🚀 Usage Examples

### 1. Create a FlashBook

```dart
final bookService = Get.find<BookService>();
final vocabService = Get.find<VocabularyService>();

// Create book
final book = await bookService.createNewBook(
  title: 'IELTS Vocabulary',
  description: 'Essential words for IELTS',
  category: 'English Learning',
);

// Add vocabularies
await vocabService.addVocabToBook(
  word: 'abundant',
  meaning: 'dồi dào, phong phú',
  bookId: book.id,
  exampleSentence: 'The region has abundant natural resources.',
);
```

### 2. Create a Journal

```dart
final bookService = Get.find<BookService>();
final journalService = Get.find<JournalService>();

// Create journal book
final journal = await bookService.createNewBook(
  title: 'My 2025 Journal',
  description: 'Personal reflections',
  category: 'Personal',
);

// Update book type to journal
journal.type = BookType.journal;
await bookService.updateBook(journal);

// Add entries
await journalService.createEntry(
  bookId: journal.id,
  date: DateTime.now(),
  title: 'A Great Day',
  content: 'Today was amazing! I learned so much...',
  mood: 'happy',
  tags: ['gratitude', 'learning'],
);

// Get statistics
final stats = journalService.getBookStatistics(journal.id);
print('Total entries: ${stats['totalEntries']}');
print('Total words: ${stats['totalWords']}');
print('Mood distribution: ${stats['moodDistribution']}');
```

### 3. Create a Story

```dart
final bookService = Get.find<BookService>();
final storyService = Get.find<StoryService>();

// Create story book
final story = await bookService.createNewBook(
  title: 'The Adventure Begins',
  description: 'An epic fantasy tale',
  category: 'Fantasy',
  author: 'John Doe',
);

// Update book type to story
story.type = BookType.story;
await bookService.updateBook(story);

// Add chapters
await storyService.createChapter(
  bookId: story.id,
  chapterNumber: 1,
  title: 'The Awakening',
  content: 'In a land far away...',
  summary: 'The hero discovers their destiny',
);

// Track reading progress
final chapter = storyService.getChapterByNumber(story.id, 1);
await storyService.updateProgress(chapter!, 500); // Read 500 characters

// Get statistics
final stats = storyService.getBookStatistics(story.id);
print('Progress: ${stats['progressPercent']}%');
print('Chapters completed: ${stats['completedChapters']}/${stats['totalChapters']}');
```

### 4. Import/Export Books

```dart
final importExportService = Get.find<BookImportExportService>();

// Export a book
final jsonString = await importExportService.exportBook(bookId);
await importExportService.exportBookToFile(
  bookId,
  '/storage/emulated/0/Download/my_book.json',
);

// Preview import
final preview = importExportService.getImportPreview(jsonString);
print('Title: ${preview['title']}');
print('Type: ${preview['type']}');
print('Items: ${preview['itemCount']} ${preview['itemType']}');

// Import a book
try {
  final newBookId = await importExportService.importBook(
    jsonString,
    overwrite: false, // Set true to replace existing
  );
  print('Imported successfully! New book ID: $newBookId');
} catch (e) {
  print('Import failed: $e');
}
```

---

## 📊 Service Methods Reference

### BookService
```dart
loadAllBooks()                  // Load all books
getBook(bookId)                 // Get single book
createNewBook(...)              // Create new book
updateBook(book)                // Update book
deleteBook(bookId)              // Delete book
getRecentBooks(limit: 5)        // Get recent books
getBooksByCategory(category)    // Filter by category
```

### VocabularyService (FlashBook)
```dart
addVocabToBook(...)             // Add vocabulary
getByBookIdSorted(bookId)       // Get sorted vocabs
reviewVocabulary(vocab, quality) // SRS review
getDueForReview(bookId)         // Get due vocabs
getByReviewStatus(bookId, status) // Filter by status
```

### JournalService (Journal)
```dart
createEntry(...)                // Create entry
updateEntry(entry)              // Update entry
getEntriesByBookIdSorted(bookId) // Get sorted entries
getEntriesByDateRange(...)      // Filter by date
getEntriesByMood(bookId, mood)  // Filter by mood
getEntriesByTag(bookId, tag)    // Filter by tag
searchEntries(bookId, keyword)  // Search entries
getBookStatistics(bookId)       // Get stats
```

### StoryService (Story)
```dart
createChapter(...)              // Create chapter
getChaptersByBookIdSorted(bookId) // Get sorted chapters
getChapterByNumber(bookId, num) // Get specific chapter
updateProgress(chapter, pos)    // Update reading progress
markCompleted(chapter)          // Mark as read
getCurrentReadingChapter(bookId) // Get current chapter
getNextUnreadChapter(bookId)    // Get next unread
getBookStatistics(bookId)       // Get stats
```

### BookImportExportService
```dart
exportBook(bookId)              // Export to JSON string
exportBookToFile(bookId, path)  // Export to file
importBook(jsonString, overwrite) // Import from JSON
importBookFromFile(filePath, overwrite) // Import from file
validateImportJson(jsonString)  // Validate format
getImportPreview(jsonString)    // Preview before import
```

---

## 🗂️ Example JSON Files

Check these files for format reference:
- `assets/examples/flashbook_example.json`
- `assets/examples/journal_example.json`
- `assets/examples/story_example.json`

---

## 📝 Migration Notes

### Existing Books
All existing books automatically have `type = BookType.flashBook` due to the defaultValue in Hive adapter.

### Updating Book Type
```dart
final book = bookService.getBook(bookId);
book.type = BookType.journal; // or story
await bookService.updateBook(book);
```

### Type-Specific Config
Use `typeConfig` for custom settings:
```dart
book.typeConfig = {
  'defaultMood': 'neutral',
  'autoSave': true,
  'theme': 'dark',
};
```

---

## 🎨 UI Development Tips

### Journal UI Ideas:
- Calendar view with mood icons
- Mood chart/statistics
- Tag cloud for filtering
- Search by keyword or date range

### Story UI Ideas:
- Chapter list with progress bars
- Reading position bookmark
- Night mode for reading
- Estimated time remaining
- "Continue reading" button (auto-opens current chapter)

### Import/Export UI:
- Share button in book details
- Import from file picker
- Preview dialog before import
- Duplicate detection warning

---

## 🐛 Common Issues

### Issue: "Book not found"
**Solution**: Make sure book exists and ID is correct
```dart
final book = bookService.getBook(bookId);
if (book == null) {
  print('Book not found');
  return;
}
```

### Issue: "Duplicate chapter number"
**Solution**: Check existing chapters before creating
```dart
final existing = storyService.getChapterByNumber(bookId, chapterNum);
if (existing != null) {
  print('Chapter $chapterNum already exists');
  return;
}
```

### Issue: Import fails with "Book already exists"
**Solution**: Use overwrite flag or rename the book
```dart
await importExportService.importBook(json, overwrite: true);
```

---

## 📚 Architecture Docs

For detailed architecture information, see:
- `BOOK_TYPES_ARCHITECTURE.md` - Complete design document
- `LAYER_ARCHITECTURE.md` - Clean architecture explanation
- `MIGRATION_PLAN.md` - Service migration details

---

Happy coding! 🎉
