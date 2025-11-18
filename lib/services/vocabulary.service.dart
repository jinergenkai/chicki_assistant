import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VocabularyService {
  static const String boxName = "vocabularyBox1";

  late Box<Vocabulary> _box;

  /// Khởi tạo Hive box, gọi 1 lần khi app start
  Future<void> init() async {
    _box = await Hive.openBox<Vocabulary>(boxName);
  }

  /// Thêm từ mới hoặc update nếu đã tồn tại
  Future<void> upsertVocabulary(Vocabulary vocab) async {
    if (vocab.id != null) {
      await _box.put(vocab.id, vocab);
    } else {
      final key = await _box.add(vocab);
      vocab.id = key as int?;
      await _box.put(key, vocab);
    }
  }

  /// Lấy tất cả từ (có thể filter deleted = false)
  List<Vocabulary> getAll({bool includeDeleted = false}) {
    final all = _box.values.toList();
    if (!includeDeleted) {
      return all.where((v) => !v.isDeleted).toList();
    }
    return all;
  }

  /// Lấy từ chưa sync
  List<Vocabulary> getUnsynced() {
    return _box.values.where((v) => !v.isSync).toList();
  }

  /// Lấy từ theo tag
  List<Vocabulary> getByTag(String tag) {
    return _box.values
        .where((v) => v.tags != null && v.tags!.contains(tag) && !v.isDeleted)
        .toList();
  }

  /// Lấy từ theo bookId
  List<Vocabulary> getByBookId(String bookId) {
    return _box.values
        .where((v) => v.bookId == bookId && !v.isDeleted)
        .toList();
  }

  /// Mark xóa từ (offline delete)
  Future<void> markDeleted(Vocabulary vocab) async {
    vocab.isDeleted = true;
    vocab.isSync = false; // đánh dấu chưa sync
    await _box.put(vocab.id, vocab);
  }

  /// Delete hoàn toàn (local only)
  Future<void> deleteVocabulary(Vocabulary vocab) async {
    if (vocab.id != null) {
      await _box.delete(vocab.id);
    }
  }

  /// Lấy từ theo familiarity > threshold
  List<Vocabulary> getByFamiliarity(double minFamiliarity) {
    return _box.values
        .where((v) => (v.familiarity ?? 0) >= minFamiliarity && !v.isDeleted)
        .toList();
  }

  /// Close box khi không dùng nữa
  Future<void> close() async {
    await _box.close();
  }

  /// Add a vocabulary to a book with validation and proper ordering
  Future<Vocabulary> addVocabToBook({
    required String word,
    required String meaning,
    required String bookId,
    String? topic,
    String? pronunciation,
    String? exampleSentence,
    String? exampleTranslation,
    int? difficulty,
  }) async {
    // Check for duplicate word in the same book
    final existingVocab = getByBookId(bookId);
    if (existingVocab.any((v) => v.word.toLowerCase() == word.toLowerCase())) {
      throw Exception('Word "$word" already exists in this book');
    }

    // Calculate next orderIndex
    int nextOrderIndex = 0;
    if (existingVocab.isNotEmpty) {
      final maxIndex = existingVocab
          .map((v) => v.orderIndex ?? 0)
          .reduce((a, b) => a > b ? a : b);
      nextOrderIndex = maxIndex + 1;
    }

    final now = DateTime.now();
    final vocab = Vocabulary(
      word: word.trim(),
      meaning: meaning.trim(),
      originLanguage: 'en', // Default, can be parameterized
      targetLanguage: 'vi', // Default, can be parameterized
      bookId: bookId,
      topic: topic,
      pronunciation: pronunciation,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      difficulty: difficulty ?? 3,
      orderIndex: nextOrderIndex,
      reviewStatus: 'new',
      familiarity: 0.0,
      easeFactor: 2.5, // Default SM-2 ease factor
      interval: 0,
      reviewCount: 0,
      createdAt: now,
      updatedAt: now,
      isSync: false,
      isDeleted: false,
    );

    await upsertVocabulary(vocab);
    return vocab;
  }

  /// Get vocabularies sorted by orderIndex
  List<Vocabulary> getByBookIdSorted(String bookId) {
    final vocabs = getByBookId(bookId);
    vocabs.sort((a, b) {
      final aIndex = a.orderIndex ?? 0;
      final bIndex = b.orderIndex ?? 0;
      return aIndex.compareTo(bIndex);
    });
    return vocabs;
  }

  /// Get vocabularies due for review (SRS)
  List<Vocabulary> getDueForReview(String bookId) {
    final now = DateTime.now();
    return _box.values
        .where((v) =>
            v.bookId == bookId &&
            !v.isDeleted &&
            (v.nextReviewDate == null || v.nextReviewDate!.isBefore(now)))
        .toList();
  }

  /// Update vocabulary after review (SRS)
  Future<void> reviewVocabulary(Vocabulary vocab, int quality) async {
    // SM-2 Algorithm implementation
    // quality: 0-5 (0=complete blackout, 5=perfect response)

    vocab.reviewCount = (vocab.reviewCount ?? 0) + 1;
    vocab.lastReviewedAt = DateTime.now();

    if (quality < 3) {
      // Failed review - reset to beginning
      vocab.interval = 0;
      vocab.reviewStatus = 'learning';
      vocab.familiarity = (vocab.familiarity ?? 0) * 0.8; // Reduce familiarity
    } else {
      // Successful review - apply SM-2
      final oldEaseFactor = vocab.easeFactor ?? 2.5;
      final newEaseFactor = oldEaseFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      vocab.easeFactor = newEaseFactor.clamp(1.3, 2.5);

      if (vocab.interval == 0) {
        vocab.interval = 1; // First successful review
      } else if (vocab.interval == 1) {
        vocab.interval = 6; // Second successful review
      } else {
        vocab.interval =
            (vocab.interval! * vocab.easeFactor!).round();
      }

      // Update familiarity
      vocab.familiarity = ((vocab.familiarity ?? 0) + (quality * 5))
          .clamp(0.0, 100.0);

      // Update review status
      if (vocab.familiarity! >= 80) {
        vocab.reviewStatus = 'mastered';
      } else if (vocab.familiarity! >= 50) {
        vocab.reviewStatus = 'reviewing';
      } else {
        vocab.reviewStatus = 'learning';
      }
    }

    // Calculate next review date
    vocab.nextReviewDate =
        DateTime.now().add(Duration(days: vocab.interval ?? 1));

    vocab.updatedAt = DateTime.now();
    vocab.isSync = false;

    await upsertVocabulary(vocab);
  }

  /// Get vocabulary by review status
  List<Vocabulary> getByReviewStatus(String bookId, String status) {
    return _box.values
        .where((v) =>
            v.bookId == bookId &&
            !v.isDeleted &&
            v.reviewStatus == status)
        .toList();
  }
}
