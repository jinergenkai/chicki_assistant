import 'package:hive/hive.dart';

part 'friend.g.dart';

@HiveType(typeId: 1)
class Friend extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime birthDate;

  @HiveField(2)
  String? avatarIcon;

  Friend({
    required this.name,
    required this.birthDate,
    this.avatarIcon,
  });

  // Calculate days until next birthday
  int getDaysUntilBirthday() {
    final now = DateTime.now();
    final nextBirthday = DateTime(
      now.year,
      birthDate.month,
      birthDate.day,
    );

    if (nextBirthday.isBefore(now)) {
      return DateTime(
        now.year + 1,
        birthDate.month,
        birthDate.day,
      ).difference(now).inDays;
    }

    return nextBirthday.difference(now).inDays;
  }

  static List<String> giftSuggestions = [
    "Gấu bông",
    "Trà sữa",
    "Nến thơm",
    "Thiệp viết tay",
    "Bánh sinh nhật mini",
    "Sổ tay cute",
    "Móc khóa dễ thương",
    "Sticker set",
    "Hộp đựng bút pastel",
    "Vòng tay handmade"
  ];

  String getRandomGift() {
    giftSuggestions.shuffle();
    return giftSuggestions.first;
  }
}