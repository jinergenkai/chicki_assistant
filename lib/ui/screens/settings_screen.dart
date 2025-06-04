import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chickies_ui/chickies_ui.dart';
import 'package:chicki_buddy/controllers/birthday_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BirthdayController>();

    return Scaffold(
      appBar: const ChickiesAppBar(
        title: '⚙️ Cài đặt',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ChickiesContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý dữ liệu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ChickiesButton(
                  onPressed: () {
                    controller.initDemoDataIfEmpty();
                    Get.snackbar(
                      '✅ Thành công',
                      'Đã thêm dữ liệu mẫu',
                      backgroundColor: Colors.white,
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle),
                      SizedBox(width: 8),
                      Text('Thêm dữ liệu mẫu'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ChickiesButton(
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Xác nhận'),
                        content: const Text('Bạn có chắc muốn xóa tất cả dữ liệu không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Hủy'),
                          ),
                          ChickiesButton(
                            onPressed: () {
                              controller.resetAllData();
                              Get.back();
                              Get.snackbar(
                                '✅ Thành công',
                                'Đã xóa tất cả dữ liệu',
                                backgroundColor: Colors.white,
                              );
                            },
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_forever),
                      SizedBox(width: 8),
                      Text('Xóa tất cả dữ liệu'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}