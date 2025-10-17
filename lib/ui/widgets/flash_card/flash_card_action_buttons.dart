import 'package:flutter/material.dart';

class FlashCardActionButtons extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onFlip;
  final VoidCallback onNext;
  final bool isFlipped;

  const FlashCardActionButtons({
    super.key,
    required this.onPrevious,
    required this.onFlip,
    required this.onNext,
    required this.isFlipped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: "previous",
          onPressed: onPrevious,
          backgroundColor: Colors.orange.shade400,
          child: const Icon(Icons.skip_previous, color: Colors.white),
        ),
        FloatingActionButton(
          heroTag: "flip",
          onPressed: onFlip,
          backgroundColor: Colors.blue.shade600,
          child: Icon(
            isFlipped ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
        ),
        FloatingActionButton(
          heroTag: "next",
          onPressed: onNext,
          backgroundColor: Colors.green.shade400,
          child: const Icon(Icons.skip_next, color: Colors.white),
        ),
      ],
    );
  }
}