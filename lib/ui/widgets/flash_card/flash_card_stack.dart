import 'dart:math';

import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'flash_card.dart';

class FlashCardStack extends StatelessWidget {
  final List<Vocabulary> vocabList;
  final int currentIndex;
  final double scaleValue;
  final double opacityValue;
  final Widget Function(Vocabulary vocab, int index, {bool isTop}) cardBuilder;

  const FlashCardStack({
    super.key,
    required this.vocabList,
    required this.currentIndex,
    required this.scaleValue,
    required this.opacityValue,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stackCards = [];
    // Add background cards (next 2 cards)
    for (int i = 3; i >= 1; i--) {
      int cardIndex = (currentIndex + i) % vocabList.length;
      final random = Random(cardIndex);
      final angle = (random.nextDouble() - 0.5) * 0.1;
      stackCards.add(
        Positioned(
          top: i * 8.0,
            child: Transform.rotate(
              angle: angle,
              child: cardBuilder(vocabList[cardIndex], cardIndex, isTop: false),
            ),
        ),
      );
    }
    // Add top card
    stackCards.add(
      Positioned(
        top: 0,
        child: cardBuilder(vocabList[currentIndex], currentIndex, isTop: true),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: stackCards,
    );
  }
}