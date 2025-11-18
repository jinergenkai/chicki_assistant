import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'topic.g.dart';

@HiveType(typeId: 201)
@JsonSerializable()
class Topic extends HiveObject {
  @HiveField(0)
  String id; // Unique topic ID

  @HiveField(1)
  String title; // Topic name

  @HiveField(2)
  List<String> vocabIds; // List of vocabulary IDs (instead of embedded objects)

  @HiveField(3)
  String bookId; // Linked book ID

  @HiveField(4)
  DateTime? createdAt; // Timestamp when topic was created

  @HiveField(5)
  int? orderIndex; // Order of topic in book (for sorting)

  @HiveField(6)
  String? description; // Optional description of the topic

  Topic({
    required this.id,
    required this.title,
    required this.vocabIds,
    required this.bookId,
    this.createdAt,
    this.orderIndex,
    this.description,
  });

    factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}