import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chicki_buddy/models/friend.dart';

class BirthdayController extends GetxController {
  final RxList<Friend> friends = <Friend>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadFriends();
    initDemoDataIfEmpty();
  }

  void loadFriends() {
    final box = Hive.box<Friend>('friends');
    friends.value = box.values.toList();
    sortFriendsByNextBirthday();
  }

  void initDemoDataIfEmpty() {
    final box = Hive.box<Friend>('friends');
    if (box.isEmpty) {
      final demoFriends = [
        Friend(
          name: "Thanh Phong",
          birthDate: DateTime(1995, 3, 15),
        ),
        Friend(
          name: "Đăng Khoa",
          birthDate: DateTime(1994, 7, 22),
        ),
        Friend(
          name: "Khánh Linh",
          birthDate: DateTime(1997, 11, 8),
        ),
        Friend(
          name: "Gia Tín",
          birthDate: DateTime(1996, 9, 30),
        ),
      ];

      for (var friend in demoFriends) {
        box.add(friend);
      }
      loadFriends();
    }
  }

  Future<void> resetAllData() async {
    final box = Hive.box<Friend>('friends');
    await box.clear();
    loadFriends();
  }

  void addFriend(Friend friend) {
    final box = Hive.box<Friend>('friends');
    box.add(friend);
    loadFriends();
  }

  void deleteFriend(Friend friend) {
    final box = Hive.box<Friend>('friends');
    friend.delete();
    loadFriends();
  }

  void sortFriendsByNextBirthday() {
    friends.sort((a, b) {
      final daysA = a.getDaysUntilBirthday();
      final daysB = b.getDaysUntilBirthday();
      return daysA.compareTo(daysB);
    });
  }

  String getRandomGiftFor(Friend friend) {
    return friend.getRandomGift();
  }

  String getRandomGift() {
    Friend.giftSuggestions.shuffle();
    return Friend.giftSuggestions.first;
  }

  List<Friend> getBirthdaysOnDay(DateTime date) {
    return friends.where((friend) {
      return friend.birthDate.month == date.month &&
             friend.birthDate.day == date.day;
    }).toList();
  }
}