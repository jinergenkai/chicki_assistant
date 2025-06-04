import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chickies_ui/chickies_ui.dart';
import 'package:chicki_buddy/controllers/birthday_controller.dart';
import 'package:chicki_buddy/models/friend.dart';
import 'package:chicki_buddy/services/notification_service.dart';

class BirthdayListScreen extends StatelessWidget {
  const BirthdayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BirthdayController());

    return Scaffold(
      appBar: const ChickiesAppBar(
        title: '🎂 Danh sách sinh nhật',
      ),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.friends.length,
        itemBuilder: (context, index) {
          final friend = controller.friends[index];
          return _FriendCard(friend: friend);
        },
      )),
      floatingActionButton: ChickiesButton(
        onPressed: () => _showAddFriendDialog(context),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add),
            SizedBox(width: 8),
            Text('Thêm bạn mới'),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime? selectedDate;

    Get.dialog(
      AlertDialog(
        title: const Text('Thêm bạn mới'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                ChickiesButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                  child: const Text('Chọn ngày sinh'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ChickiesButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && selectedDate != null) {
                final controller = Get.find<BirthdayController>();
                controller.addFriend(Friend(
                  name: nameController.text,
                  birthDate: selectedDate!,
                ));
                Get.back();
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Friend friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    final daysUntil = friend.getDaysUntilBirthday();
    final isUpcoming = daysUntil <= 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ChickiesContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'avatar_${friend.name}',
                  child: CircleAvatar(
                    backgroundColor: isUpcoming ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    child: Text(
                      friend.name[0],
                      style: TextStyle(
                        color: isUpcoming ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.cake,
                            size: 16,
                            color: isUpcoming ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${friend.birthDate.day}/${friend.birthDate.month}',
                            style: TextStyle(
                              color: isUpcoming ? Colors.red : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUpcoming ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$daysUntil ngày nữa',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUpcoming ? Colors.red : Colors.grey,
                                fontWeight: isUpcoming ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ChickiesButton(
                onPressed: () async {
                  try {
                    await NotificationService().showBirthdayNotification(friend.name);
                    Get.snackbar(
                      '✅ Thành công',
                      'Đã gửi chúc mừng sinh nhật đến ${friend.name}!',
                      backgroundColor: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      '❌ Lỗi',
                      e.toString(),
                      backgroundColor: Colors.white,
                    );
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration),
                    SizedBox(width: 8),
                    Text('Gửi chúc mừng'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}