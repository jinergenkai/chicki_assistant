import 'package:hive/hive.dart';
import 'vocabulary.dart';

part 'topic.g.dart';

@HiveType(typeId: 201)
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
}