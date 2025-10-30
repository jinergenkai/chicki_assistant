import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:moon_design/moon_design.dart';
import 'flash_card_swipe_overlay.dart';

class FlashCard extends StatelessWidget {
  final Vocabulary vocab;
  final double flipValue;
  final VoidCallback onTap;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final Offset swipeOffset;
  final double swipeRotation;
  final Widget frontSide;
  final Widget backSide;

  const FlashCard({
    super.key,
    required this.vocab,
    required this.flipValue,
    required this.onTap,
    this.onPanUpdate,
    this.onPanEnd,
    required this.swipeOffset,
    required this.swipeRotation,
    required this.frontSide,
    required this.backSide,
  });

  @override
  Widget build(BuildContext context) {
    // Separate translate/rotate from flip for better overlay positioning
    final swipeMatrix = Matrix4.identity()
      ..translate(swipeOffset.dx, swipeOffset.dy)
      ..rotateZ(swipeRotation);

    final flipMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(flipValue * 3.14159);

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: swipeMatrix,
        child: SizedBox(
          width: 300,
          height: 400,
          child: Stack(
            children: [
              Transform(
                alignment: Alignment.center,
                transform: flipMatrix,
                child: MoonClipSquircleRect(
                  radius: MoonSquircleBorderRadius(cornerRadius: 48, cornerSmoothing: 0.9),
                  child: RandomGradient(
                    vocab.word,
                    seed: "flashCardGradient",
                    child: Container(
                      width: 300,
                      height: 400,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 300,
                        height: 400,
                        child: flipValue < 0.5
                            ? frontSide
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(3.14159),
                                child: backSide,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              FlashCardSwipeOverlay(
                swipeProgress: swipeOffset.dx / 150,
                cardWidth: 300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}