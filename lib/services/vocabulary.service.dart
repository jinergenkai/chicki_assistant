import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VocabularyService {
  static const String boxName = "vocabularyBox1";

  late Box<Vocabulary> _box;

  /// Khởi tạo Hive box, gọi 1 lần khi app start
  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(VocabularyAdapter());
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
}
