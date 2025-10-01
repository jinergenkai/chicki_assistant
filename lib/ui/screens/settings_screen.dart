import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:moon_design/moon_design.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<AppConfigController>();

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('⚙️ Cài đặt'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Giao diện & Ngôn ngữ
          Obx(() {
            int themeIndex = {
              'system': 0,
              'light': 1,
              'dark': 2,
            }[appConfig.themeMode.value] ?? 0;
            String langLabel = appConfig.language.value == 'en'
                ? 'English'
                : 'Tiếng Việt';

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
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
                    'Giao diện & Ngôn ngữ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Theme chọn bằng MoonSegmentedControl
                  Row(
                    children: [
                      const Text('Chủ đề:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MoonSegmentedControl(
                          segments: const [
                            Segment(label: Text('Hệ thống')),
                            Segment(label: Text('Sáng')),
                            Segment(label: Text('Tối')),
                          ],
                          initialIndex: themeIndex,
                          onSegmentChanged: (idx) {
                            final mode = ['system', 'light', 'dark'][idx];
                            appConfig.themeMode.value = mode;
                            appConfig.saveConfig();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Language chọn bằng MoonDropdown
                  Row(
                    children: [
                      const Text('Ngôn ngữ:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            return MoonDropdown(
                              show: false,
                              content: const SizedBox.shrink(),
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (ctx) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MoonMenuItem(
                                          onTap: () {
                                            appConfig.language.value = 'vi';
                                            appConfig.saveConfig();
                                            Navigator.of(ctx).pop();
                                          },
                                          label: const Text('Tiếng Việt'),
                                        ),
                                        MoonMenuItem(
                                          onTap: () {
                                            appConfig.language.value = 'en';
                                            appConfig.saveConfig();
                                            Navigator.of(ctx).pop();
                                          },
                                          label: const Text('English'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(langLabel),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          // Quản lý dữ liệu
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