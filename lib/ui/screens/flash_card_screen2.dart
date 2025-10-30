import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/services/intent_bridge_service.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_stack.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_action_bar.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_progress_indicator.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_front_side.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_back_side.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

class FlashCardScreen2 extends StatefulWidget {
  final Book book;
  const FlashCardScreen2({super.key, required this.book});

  @override
  State<FlashCardScreen2> createState() => _FlashCardScreen2State();
}

class _FlashCardScreen2State extends State<FlashCardScreen2> with TickerProviderStateMixin {
  final VocabularyService service = VocabularyService();
  List<Vocabulary> vocabList = [];
  int currentIndex = 0;
  bool isLoading = true;
  String? errorMessage;

  late AnimationController _swipeController;
  late AnimationController _flipController;
  late AnimationController _stackController;

  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  bool _isFlipped = false;
  final ValueNotifier<Offset> _swipeOffsetNotifier = ValueNotifier(Offset.zero);
  final ValueNotifier<double> _swipeRotationNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    // timeDilation = 1.0;
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stackController,
      curve: Curves.easeOut,
    ));

    service.init().then((_) {
      setState(() {
        vocabList = service.getByBookId(widget.book.id);
        isLoading = false;
        if (vocabList.isEmpty) {
          errorMessage = 'No vocabulary found for this book';
        }
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load vocabulary: $error';
      });
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _flipController.dispose();
    _stackController.dispose();
    _swipeOffsetNotifier.dispose();
    _swipeRotationNotifier.dispose();
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
    final currentVocab = vocabList[currentIndex];
    // TODO: Save difficulty to database
    // swipeRight = "Easy/Known", swipeLeft = "Hard/Need review"

    await _swipeController.forward();
    setState(() {
      currentIndex = (currentIndex + 1) % vocabList.length;
      _isFlipped = false;
    });
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
    _flipController.value = _isFlipped ? 0 : 1;
    setState(() {
      _isFlipped = !_isFlipped;
    });
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
              return FlashCard(
                vocab: vocab,
                flipValue: _flipAnimation.value,
                onTap: _flipCard,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                swipeOffset: swipeOffset,
                swipeRotation: swipeRotation,
                frontSide: FlashCardFrontSide(vocab: vocab),
                backSide: FlashCardBackSide(vocab: vocab),
              );
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
    return FlashCardStack(
      vocabList: vocabList,
      currentIndex: currentIndex,
      scaleValue: _scaleAnimation.value,
      opacityValue: 0.7,
      cardBuilder: (vocab, index, {isTop = true}) => _buildCard(vocab, index, isTop: isTop),
    );
  }

  Widget _buildActionButtons() {
    return FlashCardActionBar(
      onPrevious: () {
        setState(() {
          currentIndex = (currentIndex - 1 + vocabList.length) % vocabList.length;
          _isFlipped = false;
        });
        _flipController.reset();
      },
      onFlip: _flipCard,
      onNext: () => _completeSwipe(true),
      isFlipped: _isFlipped,
      onTextToSpeech: () {
        // TODO: Implement text-to-speech
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-Speech coming soon!')),
        );
      },
      onFavorite: () {
        // TODO: Implement favorite toggle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorite feature coming soon!')),
        );
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
    );
  }

  Widget _buildProgressIndicator() {
    return FlashCardProgressIndicator(
      currentIndex: currentIndex,
      totalCount: vocabList.length,
    );
  }

  // void triggerOpenBook(Book book) {
  //   Navigator.of(context).push(MaterialPageRoute(
  //     builder: (context) => FlashCardScreen2(book: book),
  //   ));
  // }

  void clickExit() {
    IntentBridgeService.triggerUIIntent(
      intent: 'exit',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    Widget bodyContent;
    if (isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null || vocabList.isEmpty) {
      bodyContent = Center(
        child: Text(
          errorMessage ?? 'No vocabulary found for this book',
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
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              child: _buildActionButtons(),
            ),
          ),
        ],
      );
    }

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
              if (!isLoading && vocabList.isNotEmpty)
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

              await service.upsertVocabulary(vocab);
              Navigator.of(context).pop();
              setState(() {
                vocabList = service.getByBookId(widget.book.id);
              });
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
