import 'package:hive/hive.dart';
import 'book.dart';

part 'user.g.dart';

@HiveType(typeId: 202)
class User extends HiveObject {
  @HiveField(0)
  String id; // User ID

  @HiveField(1)
  String email; // Login email

  @HiveField(2)
  List<String> ownedBooks; // IDs of purchased/created books

  @HiveField(3)
  Map<String, double> progress; // bookId → % learned

  @HiveField(4)
  List<Book> customBooks; // User-created books

  User({
    required this.id,
    required this.email,
    required this.ownedBooks,
    required this.progress,
    required this.customBooks,
  });
}