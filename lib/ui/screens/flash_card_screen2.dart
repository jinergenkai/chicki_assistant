import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/ui/widgets/vocabulary/add_vocabulary_button.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_stack.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_action_buttons.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_progress_indicator.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_front_side.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card_back_side.dart';

class FlashCardScreen2 extends StatefulWidget {
  const FlashCardScreen2({super.key});

  @override
  State<FlashCardScreen2> createState() => _FlashCardScreen2State();
}

class _FlashCardScreen2State extends State<FlashCardScreen2> with TickerProviderStateMixin {
  final VocabularyService service = VocabularyService();
  List<Vocabulary> vocabList = [];
  int currentIndex = 0;

  late AnimationController _swipeController;
  late AnimationController _flipController;
  late AnimationController _stackController;

  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  bool _isFlipped = false;
  Offset _swipeOffset = Offset.zero;
  double _swipeRotation = 0;

  @override
  void initState() {
    super.initState();
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
        vocabList = service.getAll();
      });
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _flipController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset += details.delta;
      _swipeRotation = (_swipeOffset.dx / 300).clamp(-0.3, 0.3);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_swipeOffset.dx.abs() > screenWidth * 0.3) {
      _completeSwipe(_swipeOffset.dx > 0);
    } else {
      _resetCard();
    }
  }

  void _completeSwipe(bool swipeRight) async {
    await _swipeController.forward();
    setState(() {
      currentIndex = (currentIndex + 1) % vocabList.length;
      _isFlipped = false;
      _swipeOffset = Offset.zero;
      _swipeRotation = 0;
    });
    _swipeController.reset();
    _stackController.forward();
  }

  void _resetCard() {
    setState(() {
      _swipeOffset = Offset.zero;
      _swipeRotation = 0;
    });
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Widget _buildCard(Vocabulary vocab, int index, {bool isTop = true}) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _stackController,
          builder: (context, child) {
            double scale = isTop ? 1.0 : _scaleAnimation.value;
            double opacity = isTop ? 1.0 : 0.7;
            return Transform.scale(
              scale: scale,
              child: FlashCard(
                vocab: vocab,
                flipValue: _flipAnimation.value,
                onTap: _flipCard,
                onPanUpdate: isTop ? _handlePanUpdate : null,
                onPanEnd: isTop ? _handlePanEnd : null,
                swipeOffset: isTop ? _swipeOffset : Offset.zero,
                swipeRotation: isTop ? _swipeRotation : 0,
                frontSide: FlashCardFrontSide(vocab: vocab),
                backSide: FlashCardBackSide(vocab: vocab),
              ),
            );
          },
        );
      },
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
    return FlashCardActionButtons(
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
    );
  }

  Widget _buildProgressIndicator() {
    return FlashCardProgressIndicator(
      currentIndex: currentIndex,
      totalCount: vocabList.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (vocabList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flash Cards'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        floatingActionButton: AddVocabularyButton(
          service: service,
          onAdded: () {
            setState(() {
              vocabList = service.getAll();
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Flash Cards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProgressIndicator(),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: _buildCardStack(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
      floatingActionButton: AddVocabularyButton(
        service: service,
        onAdded: () {
          setState(() {
            vocabList = service.getAll();
          });
        },
      ),
    );
  }
}