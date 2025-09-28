import 'package:flutter/material.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/ui/widgets/vocabulary/add_vocabulary_button.dart';

class FlashCardScreen extends StatefulWidget {
  const FlashCardScreen({super.key});

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen>
    with TickerProviderStateMixin {
  final VocabularyService service = VocabularyService();
  List<Vocabulary> vocabList = [];
  int currentIndex = 0;
  
  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _flipController;
  late AnimationController _stackController;
  
  // Animations
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  
  // Swipe state
  bool _isFlipped = false;
  Offset _swipeOffset = Offset.zero;
  double _swipeRotation = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
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
    
    // Setup animations
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

    // Load vocabulary data
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
      // Complete the swipe
      _completeSwipe(_swipeOffset.dx > 0);
    } else {
      // Return to center
      _resetCard();
    }
  }

  void _completeSwipe(bool swipeRight) async {
    // Animate card off screen
    await _swipeController.forward();
    
    // Move to next card
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
      animation: Listenable.merge([_flipController, _stackController]),
      builder: (context, child) {
        double scale = isTop ? 1.0 : _scaleAnimation.value;
        double opacity = isTop ? 1.0 : 0.7;
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: _flipCard,
              onPanUpdate: isTop ? _handlePanUpdate : null,
              onPanEnd: isTop ? _handlePanEnd : null,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_flipAnimation.value * 3.14159),
                child: Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                        Colors.purple.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _flipAnimation.value < 0.5
                        ? _buildFrontSide(vocab)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(3.14159),
                            child: _buildBackSide(vocab),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontSide(Vocabulary vocab) {
    return Container(
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
    );
  }

  Widget _buildBackSide(Vocabulary vocab) {
    return Container(
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
    );
  }

  Widget _buildCardStack() {
    List<Widget> stackCards = [];
    
    // Add background cards (next 2 cards)
    for (int i = 2; i >= 1; i--) {
      int cardIndex = (currentIndex + i) % vocabList.length;
      stackCards.add(
        Positioned(
          top: i * 8.0,
          child: _buildCard(vocabList[cardIndex], cardIndex, isTop: false),
        ),
      );
    }
    
    // Add top card with swipe animations
    stackCards.add(
      Positioned(
        top: 0,
        child: Transform.translate(
          offset: _swipeOffset,
          child: Transform.rotate(
            angle: _swipeRotation,
            child: _buildCard(vocabList[currentIndex], currentIndex),
          ),
        ),
      ),
    );
    
    return Stack(
      alignment: Alignment.center,
      children: stackCards,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: "previous",
          onPressed: () {
            setState(() {
              currentIndex = (currentIndex - 1 + vocabList.length) % vocabList.length;
              _isFlipped = false;
            });
            _flipController.reset();
          },
          backgroundColor: Colors.orange.shade400,
          child: const Icon(Icons.skip_previous, color: Colors.white),
        ),
        FloatingActionButton(
          heroTag: "flip",
          onPressed: _flipCard,
          backgroundColor: Colors.blue.shade600,
          child: Icon(
            _isFlipped ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
        ),
        FloatingActionButton(
          heroTag: "next",
          onPressed: () => _completeSwipe(true),
          backgroundColor: Colors.green.shade400,
          child: const Icon(Icons.skip_next, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            '${currentIndex + 1} / ${vocabList.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentIndex + 1) / vocabList.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            minHeight: 4,
          ),
        ],
      ),
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