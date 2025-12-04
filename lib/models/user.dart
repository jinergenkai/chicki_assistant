import 'package:hive/hive.dart';

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
  List<String> customBookIds; // IDs of user-created books (instead of embedded objects)

  @HiveField(5)
  List<String> recentBookIds; // Recently opened book IDs (max 10, ordered by recency)

  @HiveField(6)
  List<String> favoriteBookIds; // User's favorite books

  @HiveField(7)
  int streak; // Current learning streak (consecutive days)

  @HiveField(8)
  DateTime? lastActiveDate; // Last date user was active

  @HiveField(9)
  int totalXP; // Total experience points earned

  User({
    required this.id,
    required this.email,
    required this.ownedBooks,
    required this.progress,
    this.customBookIds = const [],
    this.recentBookIds = const [],
    this.favoriteBookIds = const [],
    this.streak = 0,
    this.lastActiveDate,
    this.totalXP = 0,
  });
}