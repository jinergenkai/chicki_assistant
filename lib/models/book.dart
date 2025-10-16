import 'package:hive/hive.dart';
import 'topic.dart';

part 'book.g.dart';

@HiveType(typeId: 200)
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
  List<Topic> topics; // List of topics

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isCustom,
    this.ownerId,
    required this.topics,
  });
}