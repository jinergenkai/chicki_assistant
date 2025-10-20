// controllers/bubble_controller.dart
import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/ui/widgets/bubble_overlay_debug.dart';
import 'package:chicki_buddy/ui/widgets/bubble_overlay_smooth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/widgets/bubble_overlay.dart';

class BubbleController extends GetxController {
  OverlayEntry? _overlayEntry;
  RxBool isVisible = false.obs;

  void showBubble(GlobalKey<NavigatorState> navigatorKey) {
    if (isVisible.value) return;

    final overlay = navigatorKey.currentState!.overlay!;
    _overlayEntry = OverlayEntry(builder: (context) {
      return Builder(builder: (context) {
        return SmoothBubble(
          onClose: () => {},
        );
      });
    });

    if (_overlayEntry == null) {
      logger.info("❌ OverlayEntry is null, cannot show bubble");
      return;
    }
    overlay.insert(_overlayEntry!);
    isVisible.value = true;
  }

  void hideBubble() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    isVisible.value = false;
  }
}
