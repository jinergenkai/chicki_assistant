import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/controllers/flash_card_controller.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_stack.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_action_bar.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_progress_indicator.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_front_side.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_back_side.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/srs_review_buttons.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FlashCardScreen2 extends StatefulWidget {
  final Book book;
  const FlashCardScreen2({super.key, required this.book});

  @override
  State<FlashCardScreen2> createState() => _FlashCardScreen2State();
}

class _FlashCardScreen2State extends State<FlashCardScreen2> with TickerProviderStateMixin {
  late FlashCardController controller;
  late VocabularyService vocabService;

  late AnimationController _swipeController;
  late AnimationController _stackController;

  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  final ValueNotifier<Offset> _swipeOffsetNotifier = ValueNotifier(Offset.zero);
  final ValueNotifier<double> _swipeRotationNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();

    // Initialize controller and service
    controller = Get.put(FlashCardController(book: widget.book), tag: 'flashcard_${widget.book.id}');
    vocabService = Get.find<VocabularyService>();

    // timeDilation = 1.0;
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stackController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stackController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _stackController.dispose();
    _swipeOffsetNotifier.dispose();
    _swipeRotationNotifier.dispose();
    Get.delete<FlashCardController>(tag: 'flashcard_${widget.book.id}');
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _swipeOffsetNotifier.value += details.delta;
    _swipeRotationNotifier.value = (_swipeOffsetNotifier.value.dx / 300).clamp(-0.3, 0.3);
  }

  void _handlePanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_swipeOffsetNotifier.value.dx.abs() > screenWidth * 0.3) {
      _completeSwipe(_swipeOffsetNotifier.value.dx > 0);
    } else {
      _resetCard();
    }
  }

  void _completeSwipe(bool swipeRight) async {
    // Track difficulty based on swipe direction
    // swipeRight = "Easy/Known", swipeLeft = "Hard/Need review"
    // TODO: Save difficulty to database

    await _swipeController.forward();

    // Trigger nextCard intent instead of direct state update
    controller.nextCard();

    _swipeOffsetNotifier.value = Offset.zero;
    _swipeRotationNotifier.value = 0;
    _swipeController.reset();
    _stackController.reset();
    _stackController.forward();
  }

  void _resetCard() {
    _swipeOffsetNotifier.value = Offset.zero;
    _swipeRotationNotifier.value = 0;
  }

  void _flipCard() {
    // Trigger flipCard intent
    // Animation will be updated automatically via ever() listener
    controller.flipCard();
  }

  Future<void> _handleQualitySelected(int quality) async {
    if (controller.vocabList.isEmpty) return;

    final currentVocab = controller.vocabList[controller.currentIndex.value];

    try {
      // Review vocabulary with SRS algorithm
      await vocabService.reviewVocabulary(currentVocab, quality);

      // Show feedback toast
      String message;
      if (quality < 3) {
        message = '😫 Review again tomorrow';
      } else {
        final nextReview = currentVocab.nextReviewDate;
        if (nextReview != null) {
          final daysUntil = nextReview.difference(DateTime.now()).inDays;
          if (daysUntil == 0) {
            message = '😊 Review later today';
          } else if (daysUntil == 1) {
            message = '😊 Review tomorrow';
          } else {
            message = '😄 Review in $daysUntil days';
          }
        } else {
          message = '✅ Reviewed!';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: quality < 3 ? Colors.orange.shade700 : Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      // Auto move to next card after a short delay
      await Future.delayed(const Duration(milliseconds: 300));
      _completeSwipe(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildCard(Vocabulary vocab, int index, {bool isTop = true}) {
    // Only top card responds to flip/drag
    if (isTop) {
      return ValueListenableBuilder<Offset>(
        valueListenable: _swipeOffsetNotifier,
        builder: (context, swipeOffset, child) {
          return ValueListenableBuilder<double>(
            valueListenable: _swipeRotationNotifier,
            builder: (context, swipeRotation, _) {
              return Obx(() => FlashCard(
                vocab: vocab,
                flipValue: controller.isFlipped.value ? 1.0 : 0.0,
                onTap: _flipCard,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                swipeOffset: swipeOffset,
                swipeRotation: swipeRotation,
                frontSide: FlashCardFrontSide(vocab: vocab),
                backSide: FlashCardBackSide(vocab: vocab),
              ));
            },
          );
        },
      );
    }
    // Background cards - static, wrapped in RepaintBoundary
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _stackController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FlashCard(
              vocab: vocab,
              flipValue: 0,
              onTap: () {},
              swipeOffset: Offset.zero,
              swipeRotation: 0,
              frontSide: FlashCardFrontSide(vocab: vocab),
              backSide: FlashCardBackSide(vocab: vocab),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardStack() {
    return Obx(() => FlashCardStack(
      vocabList: controller.vocabList,
      currentIndex: controller.currentIndex.value,
      scaleValue: _scaleAnimation.value,
      opacityValue: 0.7,
      cardBuilder: (vocab, index, {isTop = true}) => _buildCard(vocab, index, isTop: isTop),
    ));
  }

  Widget _buildActionButtons() {
    return Obx(() => FlashCardActionBar(
      onPrevious: () {
        // Trigger prevCard intent
        // prevCard handler will reset isFlipped to false
        controller.prevCard();
      },
      onFlip: _flipCard,
      onNext: () => _completeSwipe(true),
      isFlipped: controller.isFlipped.value,
      onTextToSpeech: () {
        // Trigger pronounceWord intent
        controller.pronounceWord();
      },
      onFavorite: () {
        // Trigger bookmark intent
        controller.toggleBookmark();
      },
      onEdit: () {
        // TODO: Implement edit vocabulary
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit feature coming soon!')),
        );
      },
      onAddNote: () {
        // TODO: Implement add note
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add note feature coming soon!')),
        );
      },
    ));
  }

  Widget _buildProgressIndicator() {
    return Obx(() => FlashCardProgressIndicator(
      currentIndex: controller.currentIndex.value,
      totalCount: controller.vocabList.length,
    ));
  }

  // void triggerOpenBook(Book book) {
  //   Navigator.of(context).push(MaterialPageRoute(
  //     builder: (context) => FlashCardScreen2(book: book),
  //   ));
  // }

  void clickExit() {
    // Direct navigation, no intent needed for UI
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Obx(() {
      Widget bodyContent;
      if (controller.isLoading.value) {
        bodyContent = const Center(child: CircularProgressIndicator());
      } else if (controller.errorMessage.value != null || controller.vocabList.isEmpty) {
        bodyContent = Center(
          child: Text(
            controller.errorMessage.value ?? 'No vocabulary found for this book',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        bodyContent = Column(
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _buildCardStack(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 12),
                child: _buildActionButtons(),
              ),
            ),
            // SRS Review Buttons (only show when flipped)
            Obx(() => SRSReviewButtons(
              isVisible: controller.isFlipped.value && controller.vocabList.isNotEmpty,
              onQualitySelected: _handleQualitySelected,
            )),
            const SizedBox(height: 24),
          ],
        );
      }

      return _buildScaffold(book, bodyContent);
    });
  }

  Widget _buildScaffold(Book book, Widget bodyContent) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            foregroundColor: Colors.black87,
            title: Hero(
              tag: 'book_${book.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  book.title,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.grey.shade800),
                onPressed: () => clickExit(),
              ),
            ),
            actions: [
              if (!controller.isLoading.value && controller.vocabList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showAddVocabularyDialog();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 68,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  child: bodyContent,
                )),
          ),
        ],
      ),
    );
  }

  void _showAddVocabularyDialog() {
    final wordController = TextEditingController();
    final meaningController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Vocabulary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordController,
              decoration: InputDecoration(
                labelText: 'Word',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.abc_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: meaningController,
              decoration: InputDecoration(
                labelText: 'Meaning',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.translate_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final word = wordController.text.trim();
              final meaning = meaningController.text.trim();
              if (word.isEmpty) return;

              final vocab = Vocabulary(
                word: word,
                originLanguage: 'en',
                targetLanguage: 'vi',
                meaning: meaning.isEmpty ? null : meaning,
                bookId: widget.book.id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // TODO: Trigger addVocabulary intent to add vocab via foreground isolate
              // For now, reload vocabulary list
              Navigator.of(context).pop();
              controller.loadVocabulary();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
