import 'package:chicki_buddy/controllers/books_controller.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:chicki_buddy/ui/screens/book_details_screen.dart';
import 'package:chicki_buddy/ui/screens/create_book_screen.dart';
import 'package:chicki_buddy/ui/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
// ignore: unused_import
import 'package:moon_design/moon_design.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.find<BooksController>();
  late PageController _pageController;
  int _currentPage = 0;
  
  // Cache book stats (vocab count or entry count)
  Map<String, Map<String, dynamic>> bookStats = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: _currentPage,
    );

    // Wait for books to load, then load stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookStats();
    });
  }

  Future<void> _loadBookStats() async {
    final journalService = Get.find<JournalService>();

    // Load stats for all books
    for (var book in controller.books) {
      if (book.type == BookType.journal) {
        // Journal Stats
        final stats = journalService.getBookStatistics(book.id);
        bookStats[book.id] = {
          'count': stats['totalEntries'] ?? 0,
        };
      } else if (book.type == BookType.flashBook) {
        // Flashcard Stats
        final allVocabs = await _getVocabsForBook(book.id);
        final masteredCount = allVocabs.where((v) => v.reviewStatus == 'mastered').length;

        bookStats[book.id] = {
          'total': allVocabs.length,
          'mastered': masteredCount,
        };
      }
    }
    if (mounted) setState(() {});
  }

  Future<List<Vocabulary>> _getVocabsForBook(String bookId) async {
    final vocabService = Get.find<VocabularyService>();
    return vocabService.getByBookId(bookId);
  }

  void _onBookTap(Book book) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookDetailsScreen(book: book),
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Continue your reading journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Obx(() {
                 if (controller.isLoading.value && controller.books.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No books available',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: controller.books.length + 1,
                  itemBuilder: (context, index) {
                    // Animation calculations
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                        }
                        
                        return Center(
                          child: Transform.scale(
                            scale: Curves.easeOut.transform(value),
                            child: child,
                          ),
                        );
                      },
                      child: Builder(
                        builder: (context) {
                          // 1. Add Book Card (Last Item)
                          if (index == controller.books.length) {
                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const CreateBookScreen()),
                                );
                                if (result == true) {
                                  controller.loadBooks();
                                }
                              },
                              child: Container(
                                height: 400,
                                width: 260, // Match BookCard width buffer
                                alignment: Alignment.center,
                                child: Container(
                                  width: 220, // Match BookCard inner width
                                  height: 300, // Match BookCard inner height
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                      style: BorderStyle.solid
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.plus,
                                          size: 32,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'New Book',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // 2. Existing Book Card
                          final book = controller.books[index];
                          final stats = bookStats[book.id];
                          
                          return GestureDetector(
                            onTap: () => _onBookTap(book),
                            child: SizedBox(
                              height: 400, 
                              child: Center(
                                child: BookCard(
                                  id: book.id,
                                  title: book.title,
                                  desc: book.description,
                                  type: book.type,
                                  width: 220,
                                  height: 300,
                                  // Pass stats based on type
                                  totalVocabs: book.type == BookType.flashBook ? (stats?['total']) : null,
                                  masteredVocabs: book.type == BookType.flashBook ? (stats?['mastered']) : null,
                                  journalEntryCount: book.type == BookType.journal ? (stats?['count']) : null,
                                  lastOpenedAt: book.lastOpenedAt,
                                  coverId: book.coverId,
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    );
                  },
                );
              }),
            ),
            
            // Page Indicator
            Obx(() => controller.books.isNotEmpty 
              ? SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.books.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                          ? Colors.blue 
                          : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink()
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}