import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chickies_ui/chickies_ui.dart';
import 'package:chicki_buddy/controllers/birthday_controller.dart';

class GiftSuggestionsScreen extends StatelessWidget {
  const GiftSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BirthdayController>();

    return Scaffold(
      appBar: const ChickiesAppBar(
        title: '🎁 Gợi ý quà tặng',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Nhấn nút bên dưới để nhận gợi ý quà tặng ngẫu nhiên',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ChickiesButton(
                onPressed: () {
                  final gift = controller.getRandomGift();
                  Get.snackbar(
                    '🎁 Gợi ý quà tặng',
                    'Bạn có thể tặng: $gift',
                    backgroundColor: Colors.white,
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Random quà tặng'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}