import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'vocabulary.dart';

part 'topic.g.dart';

@HiveType(typeId: 201)
@JsonSerializable()
class Topic extends HiveObject {
  @HiveField(0)
  String id; // Unique topic ID

  @HiveField(1)
  String title; // Topic name

  @HiveField(2)
  List<Vocabulary> vocabList; // Vocabulary list

  @HiveField(3)
  String bookId; // Linked book ID

  Topic({
    required this.id,
    required this.title,
    required this.vocabList,
    required this.bookId,
  });

    factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}