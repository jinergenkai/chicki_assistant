import 'dart:async';

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/ui/screens/book_details_screen.dart';
import 'package:chicki_buddy/ui/screens/flash_card_screen2.dart';
import 'package:chicki_buddy/ui/widgets/book_card.dart';
import 'package:chicki_buddy/ui/widgets/flash_card/flash_card.dart';
import 'package:chicki_buddy/ui/widgets/recent_books_section.dart';
import 'package:chicki_buddy/services/data/book_data_service.dart';
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
  late BookDataService bookDataService;
  StreamSubscription? _navigationSub;
  List<Book> recentBooks = [];

  void triggerOpenBook(Book book) {
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) => BookDetailsScreen(book: book),
    // ));
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FlashCardScreen2(book: book),
    ));
  }

  Future<void> clickOpenBook(Book book) async {
    // Direct navigation - no intent needed for UI actions
    triggerOpenBook(book);
  }

  @override
  void initState() {
    super.initState();
    
    bookDataService = Get.find<BookDataService>();

    // Load recent books
    _loadRecentBooks();

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

  Future<void> _loadRecentBooks() async {
    await bookDataService.loadRecentBooks(limit: 10);
    setState(() {
      recentBooks = bookDataService.recentBooks.toList();
    });
  }

  @override
  void dispose() {
    _navigationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 195, 66, 218),
            Colors.blue,
            Color.fromARGB(255, 18, 176, 220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  double percent = (constraints.maxHeight - kToolbarHeight) / (180 - kToolbarHeight);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color.fromARGB(255, 195, 66, 218), Colors.blue, Color.fromARGB(255, 18, 176, 220)],
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
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Row(
                            children: [
                              Text(
                                'Bookstore',
                                style: TextStyle(
                                  fontSize: 36 * percent.clamp(0.7, 1.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [Shadow(blurRadius: 12, color: Colors.black26)],
                                ),
                              ),
                              IconButton(
                                onPressed: () => controller.reloadBooks(),
                                icon: const Icon(Icons.refresh, color: Colors.white),
                              )
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
                        // Recent Books Section
                        RecentBooksSection(
                          recentBooks: recentBooks,
                          onBookTap: clickOpenBook,
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
                                'ALL BOOKS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '(${controller.books.length})',
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: controller.books.length,
                            itemBuilder: (context, index) {
                              final book = controller.books[index];
                              timeDilation = 4.0;
                              return GestureDetector(
                                onLongPress: () async {
                                  await controller.reloadBooks();
                                  _loadRecentBooks(); // Refresh recent books too
                                },
                                onTap: () => clickOpenBook(book),
                                child: Hero(
                                  tag: 'book_${book.id}',
                                  child: Obx(() => BookCard(
                                        id: book.id,
                                        title: book.title,
                                        desc: book.description,
                                        isDownloaded: controller.downloadedBooks.contains(book.id),
                                        isDownloading: controller.downloadingBookId.value == book.id,
                                        progress: controller.downloadProgress.value,
                                        onDownload: () => controller.downloadBook(book.id),
                                        onRemove: () => controller.removeBook(book.id),
                                      )),
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
