import 'dart:async';

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/ui/screens/book_details_screen.dart';
import 'package:chicki_buddy/ui/screens/flash_card_screen2.dart';
import 'package:chicki_buddy/ui/widgets/book_card.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card.dart';
import 'package:chicki_buddy/ui/screens/create_book_screen.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';
import '../../controllers/books_controller.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final controller = Get.find<BooksController>(); // Use existing global instance
  StreamSubscription? _navigationSub;
  String? _selectedCategory;
  List<String> _categories = [];

  // Cache vocab stats for each book
  Map<String, Map<String, int>> bookStats = {};

  void triggerOpenBook(Book book) {
    // Navigate to BookDetailsScreen instead of directly to FlashCard
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookDetailsScreen(book: book),
    ));
  }

  Future<void> clickOpenBook(Book book) async {
    // Direct navigation - no intent needed for UI actions
    triggerOpenBook(book);
  }

  @override
  void initState() {
    super.initState();

    // Load categories
    _loadCategories();

    // Wait for books to load, then load stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookStats();
    });

    // Listen for navigation requests from controller (voice/intent triggered)
    // BooksScreen is ONLY responsible for UI navigation, not intent handling
    _navigationSub = controller.bookToNavigate.listen((book) {
      if (book != null) {
        triggerOpenBook(book);
        // Reset after navigation
        controller.bookToNavigate.value = null;
      }
    });
  }

  Future<void> _loadCategories() async {
    // Get categories from all books
    final allCategories = controller.books
        .where((b) => b.category != null && b.category!.isNotEmpty)
        .map((b) => b.category!)
        .toSet()
        .toList();
    allCategories.sort();

    setState(() {
      _categories = ['All', ...allCategories];
    });
  }

  Future<void> _loadBookStats() async {
    // Load vocab stats for all books
    print('📊 Loading book stats for ${controller.books.length} books...');

    for (var book in controller.books) {
      final allVocabs = await _getVocabsForBook(book.id);
      final masteredCount = allVocabs.where((v) => v.reviewStatus == 'mastered').length;

      bookStats[book.id] = {
        'total': allVocabs.length,
        'mastered': masteredCount,
      };

      print('📖 ${book.title}: ${allVocabs.length} words, $masteredCount mastered');
    }

    print('✅ Book stats loaded: ${bookStats.length} books');
    if (mounted) setState(() {});
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    print('🔄 Pull-to-refresh triggered');
    await controller.reloadBooks();
    await _loadCategories();
    await _loadBookStats();
    print('✅ Refresh completed');
  }

  Future<List<Vocabulary>> _getVocabsForBook(String bookId) async {
    // Use GetX-registered service instead of creating new instance
    final vocabService = Get.find<VocabularyService>();
    return vocabService.getByBookId(bookId);
  }

  List<Book> get _filteredBooks {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return controller.books;
    }
    return controller.books
        .where((b) => b.category == _selectedCategory)
        .toList();
  }

  Future<void> _showCreateBookDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateBookScreen()),
    );

    if (result == true) {
      // Reload books after creation
      await controller.reloadBooks();
      _loadCategories();
    }
  }

  @override
  void dispose() {
    _navigationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
            SliverAppBar(
              expandedHeight: 140,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: false,
              toolbarHeight: 68,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  double percent = (constraints.maxHeight - 68) / (140 - 68);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color.fromARGB(255, 194, 251, 255), Colors.blue, Color.fromARGB(255, 18, 176, 220)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: percent.clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/overlay.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Modern gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Modern shadow at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                            children: [
                              Text(
                                'Bookstore',
                                style: TextStyle(
                                  fontSize: 36 * percent.clamp(0.7, 1.0),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: const [
                                    Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2))
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showCreateBookDialog,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                          SizedBox(width: 6),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
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
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.only(top: 20, left: 0, right: 0, bottom: 0),
                child: Scrollbar(
                  child: Obx(() {
                    // Show loading indicator while fetching books
                    if (controller.isLoading.value && controller.books.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Filter
                        if (_categories.isNotEmpty)
                          Container(
                            height: 50,
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected = _selectedCategory == category ||
                                    (category == 'All' && _selectedCategory == null);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = category == 'All' ? null : category;
                                      });
                                    },
                                    backgroundColor: Colors.grey.shade100,
                                    selectedColor: Colors.blue.shade100,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    checkmarkColor: Colors.blue.shade700,
                                  ),
                                );
                              },
                            ),
                          ),

                        // All Books Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.library_books_rounded,
                                color: Colors.blue,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'All Books',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '(${_filteredBooks.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Grid View of all books
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Let CustomScrollView handle scroll
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200, // Max width per card
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.67, // 180:270 ratio
                      ),
                      itemCount: _filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = _filteredBooks[index];
                              // timeDilation = 4.0;
                              return Center( // Center card in grid cell
                                child: GestureDetector(
                                  onLongPress: () async {
                                    await controller.reloadBooks();
                                  },
                                  onTap: () => clickOpenBook(book),
                                  child: Hero(
                                    tag: 'book_${book.id}',
                                    child: 
                                      BookCard(
                                      id: book.id,
                                      title: book.title,
                                      desc: book.description,
                                      totalVocabs: bookStats[book.id]?['total'],
                                      masteredVocabs: bookStats[book.id]?['mastered'],
                                      lastOpenedAt: book.lastOpenedAt,
                                      type: book.type,
                                      coverId: book.coverId,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        ),
    );
  }
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 40);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
