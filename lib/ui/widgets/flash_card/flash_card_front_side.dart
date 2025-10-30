import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';

class FlashCardFrontSide extends StatelessWidget {
  final Vocabulary vocab;

  const FlashCardFrontSide({super.key, required this.vocab});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const Icon(
            Icons.quiz,
            size: 40,
            color: Colors.white70,
          ),
          const SizedBox(height: 20),
          Text(
            vocab.word,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (vocab.pronunciation != null) ...[
            const SizedBox(height: 12),
            Text(
              vocab.pronunciation!,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          const Text(
            'Tap để xem nghĩa',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
      ),
    );
  }
}