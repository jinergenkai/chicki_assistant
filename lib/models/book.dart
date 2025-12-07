import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

/// Source of the book
@HiveType(typeId: 201)
enum BookSource {
  @HiveField(0)
  statics, // From assets JSON

  @HiveField(1)
  userCreated, // User created custom book

  @HiveField(2)
  imported, // Downloaded/imported from friends
}

/// Type of the book
@HiveType(typeId: 202)
enum BookType {
  @HiveField(0)
  flashBook, // Vocabulary learning with flashcards

  @HiveField(1)
  journal, // Diary/Journal entries

  @HiveField(2)
  story, // Reading stories/articles
}

@HiveType(typeId: 200)
@JsonSerializable()
class Book extends HiveObject {
  @HiveField(0)
  String id; // Unique book ID

  @HiveField(1)
  String title; // Book name

  @HiveField(2)
  String description; // Short intro

  @HiveField(3)
  double price; // 0 = free, >0 = paid

  @HiveField(4)
  bool isCustom; // true if user created

  @HiveField(5)
  String? ownerId; // userId if custom book

  @HiveField(6)
  DateTime? createdAt; // Timestamp when book was created

  @HiveField(7)
  DateTime? updatedAt; // Timestamp of last update

  @HiveField(8)
  DateTime? lastOpenedAt; // Timestamp when user last opened this book (for recent books)

  @HiveField(9)
  String? version; // Book version (e.g., '1.0', '1.1') for export/import compatibility

  @HiveField(10)
  bool isPublic; // Whether this book can be shared publicly

  @HiveField(11)
  String? coverImagePath; // Local path to cover image (offline)

  @HiveField(12)
  String? author; // Book author/creator name

  @HiveField(13)
  String? category; // Category for filtering (Travel, Business, etc.)

  @HiveField(14)
  String? jsonHash; // SHA-256 hash of exported JSON for integrity verification

  @HiveField(15, defaultValue: BookSource.userCreated)
  @JsonKey(defaultValue: BookSource.userCreated)
  BookSource source; // Source of the book (static/userCreated/imported)

  @HiveField(16)
  String? originalOwnerId; // Track original creator (for imported books)

  @HiveField(17, defaultValue: BookType.flashBook)
  @JsonKey(defaultValue: BookType.flashBook)
  BookType type; // Type of book (flashBook/journal/story)

  @HiveField(18)
  Map<String, dynamic>? typeConfig; // Type-specific configuration

  @HiveField(19)
  String? coverId; // ID used for generating the cover gradient

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isCustom,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
    this.lastOpenedAt,
    this.version,
    this.isPublic = false,
    this.coverImagePath,
    this.author,
    this.category,
    this.jsonHash,
    BookSource? source,
    this.originalOwnerId,
    this.type = BookType.flashBook, // Default to flashBook
    this.typeConfig,
    this.coverId,
  }) : source = source ?? BookSource.userCreated; // Default to userCreated for backward compatibility

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);
}