// controllers/bubble_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/widgets/bubble_overlay.dart';

class BubbleController extends GetxController {
  OverlayEntry? _overlayEntry;
  RxBool isVisible = false.obs;
  Rx<Offset> position = const Offset(100, 500).obs; // vị trí mặc định

  void showBubble(GlobalKey<NavigatorState> navigatorKey) {
    if (isVisible.value) return;

    final overlay = navigatorKey.currentState!.overlay!;
    _overlayEntry = OverlayEntry(builder: (context) {
      return Obx(() => Positioned(
            left: position.value.dx,
            top: position.value.dy,
            child: BubbleOverlayWithDebug(
              onClose: hideBubble,
              onMove: (offset) => position.value = offset,
            ),
          ));
    });

    overlay.insert(_overlayEntry!);
    isVisible.value = true;
  }

  void hideBubble() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    isVisible.value = false;
  }
}
