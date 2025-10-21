import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';


part 'vocabulary.g.dart';

@HiveType(typeId: 100)
@JsonSerializable()
class Vocabulary extends HiveObject {
  @HiveField(0)
  int? id; // Primary key local, auto increment optional

  @HiveField(1)
  String word; // từ vựng chính, required

  @HiveField(2)
  String? pronunciation; // phiên âm / IPA, optional

  @HiveField(3)
  String originLanguage; // ngôn ngữ gốc, e.g., 'en', required

  @HiveField(4)
  String targetLanguage; // ngôn ngữ dịch, e.g., 'vi', required

  @HiveField(5)
  String? meaning; // nghĩa, optional nếu dữ liệu null

  @HiveField(6)
  String? exampleSentence; // ví dụ câu sử dụng từ, optional

  @HiveField(7)
  String? exampleTranslation; // dịch câu ví dụ, optional

  @HiveField(8)
  String? ttsAudioPath; // đường dẫn file audio offline, optional

  @HiveField(9)
  List<String>? synonyms; // từ đồng nghĩa, optional

  @HiveField(10)
  List<String>? antonyms; // từ trái nghĩa, optional

  @HiveField(11)
  List<String>? tags; // tags / categories, optional

  @HiveField(12)
  int? difficulty; // 1-5, optional

  @HiveField(13)
  double? familiarity; // điểm quen thuộc người dùng, 0.0–100.0, optional

  @HiveField(14)
  DateTime createdAt; // timestamp tạo từ, required

  @HiveField(15)
  DateTime updatedAt; // timestamp cập nhật, required

  @HiveField(16)
  bool isSync; // đã sync server chưa, default false

  @HiveField(17)
  bool isDeleted; // track xóa offline, default false

  // --- Added fields for advanced vocabulary DB ---
  @HiveField(18)
  String? pos; // Part of Speech (danh từ, động từ...)

  @HiveField(19)
  int? frequencyRank; // Ranking theo corpus

  @HiveField(20)
  String? sourceList; // List nguồn: oxford_3000, awl...

  @HiveField(21)
  List<String>? relatedWords; // hypernym / hyponym / collocation

  @HiveField(22)
  String? userNotes; // User ghi chú riêng

  @HiveField(23)
  String? imagePath; // Đường dẫn ảnh minh họa

  @HiveField(24)
  String? reviewStatus; // Trạng thái ôn tập SRS: new, learning, reviewing, mastered

  @HiveField(25)
  String? bookId; // ID sách gốc của từ

  @HiveField(26)
  String? topic; // Chủ đề của từ trong sách

  Vocabulary({
    this.id,
    required this.word,
    this.pronunciation,
    required this.originLanguage,
    required this.targetLanguage,
    this.meaning,
    this.exampleSentence,
    this.exampleTranslation,
    this.ttsAudioPath,
    this.synonyms,
    this.antonyms,
    this.tags,
    this.difficulty,
    this.familiarity,
    required this.createdAt,
    required this.updatedAt,
    this.isSync = false,
    this.isDeleted = false,
    // --- Added fields ---
    this.pos,
    this.frequencyRank,
    this.sourceList,
    this.relatedWords,
    this.userNotes,
    this.imagePath,
    this.reviewStatus,

    this.bookId,
    this.topic,
  });
  // NOTE: Update HiveAdapter if you change fields!

    factory Vocabulary.fromJson(Map<String, dynamic> json) => _$VocabularyFromJson(json);
  Map<String, dynamic> toJson() => _$VocabularyToJson(this);
}