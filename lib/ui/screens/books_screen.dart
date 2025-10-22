// Modern Books Screen with Moon Design grid and download simulation

import 'dart:async';

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/ui/screens/book_details_screen.dart';
import 'package:chicki_buddy/ui/widgets/book_card.dart';
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
  final controller = Get.put(BooksController());
  StreamSubscription? _voiceActionSub;

  void openBook(Book book) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookDetailsScreen(book: book),
    ));
  }

  @override
  void initState() {
    super.initState();
    // Listen for voice action events from unified intent handler
    _voiceActionSub = eventBus.stream
        .where((e) => e.type == AppEventType.voiceAction)
        .listen((event) {
      final action = event.payload as Map<String, dynamic>;
      _handleVoiceAction(action);
    });
  }

  void _handleVoiceAction(Map<String, dynamic> action) {
    final actionType = action['action'] as String?;
    final data = action['data'] as Map<String, dynamic>?;
    
    switch (actionType) {
      case 'navigateToBook':
        // Handle book navigation from speech or UI intent
        if (data != null) {
          final bookId = data['bookId'] as String?;
          final bookName = data['bookName'] as String?;
          
          // Find book by ID or name
          Book? book;
          if (bookId != null) {
            book = controller.books.firstWhereOrNull((b) => b.id == bookId);
          } else if (bookName != null) {
            book = controller.books.firstWhereOrNull(
              (b) => b.title.toLowerCase().contains(bookName.toLowerCase())
            );
          }
          
          if (book != null) {
            openBook(book);
          }
        }
        break;
        
      case 'listBook':
        // Books list is already updated by controller
        // UI will automatically refresh via Obx
        break;
        
      default:
        // Ignore other actions
        break;
    }
  }

  @override
  void dispose() {
    _voiceActionSub?.cancel();
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
        // backgroundColor: Colors.grey[100]?.withValues(alpha: 0.0),
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
                              IconButton(onPressed: () => {
                                controller.reloadBooks()
                              }, icon: const Icon(Icons.refresh, color: Colors.white,))
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
                  // borderRadius: BorderRadius.only(
                  //   topLeft: Radius.circular(32),
                  //   topRight: Radius.circular(32),
                  // ),
                ),
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 0),
                child: Scrollbar(
                  // thumbVisibility: true,
                  child: Obx(() {
                    // Show loading indicator while fetching books
                    if (controller.isLoading.value && controller.books.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    return GridView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        // physics: const NeverScrollableScrollPhysics(),
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
                            },
                            onTap: () => openBook(book),
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

// Add this below your BooksScreen widget:
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
