import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/controllers/birthday_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BirthdayController>();

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('⚙️ Cài đặt'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
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
                ElevatedButton(
                  onPressed: () {
                    controller.initDemoDataIfEmpty();
                    Get.snackbar(
                      '✅ Thành công',
                      'Đã thêm dữ liệu mẫu',
                      backgroundColor: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                ElevatedButton(
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
                          ElevatedButton(
                            onPressed: () {
                              controller.resetAllData();
                              Get.back();
                              Get.snackbar(
                                '✅ Thành công',
                                'Đã xóa tất cả dữ liệu',
                                backgroundColor: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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