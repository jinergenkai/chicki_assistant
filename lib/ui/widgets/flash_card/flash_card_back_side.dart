import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';

class FlashCardBackSide extends StatelessWidget {
  final Vocabulary vocab;

  const FlashCardBackSide({super.key, required this.vocab});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 40,
            color: Colors.white70,
          ),
          const SizedBox(height: 20),
          Text(
            vocab.word,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (vocab.meaning != null)
            Text(
              vocab.meaning!,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 40),
          const Text(
            'Vuốt trái/phải để chuyển thẻ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      ),
    );
  }
}