// Modern Books Screen with Moon Design grid and download simulation

import 'package:chicki_buddy/ui/widgets/book_card.dart';
import 'package:flutter/material.dart';
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
                          child: Text(
                            'Bookstore',
                            style: TextStyle(
                              fontSize: 36 * percent.clamp(0.7, 1.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 12, color: Colors.black26)],
                            ),
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
                  child: GridView.builder(
                    shrinkWrap: true,
                    // physics: const AlwaysScrollableScrollPhysics(),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: controller.books.length,
                    itemBuilder: (context, index) {
                      final book = controller.books[index];
                      return Obx(() => BookCard(
                        title: book['title'] as String,
                        desc: book['desc'] as String,
                        isDownloaded: controller.downloadedBooks.contains(book['id']),
                        isDownloading: controller.downloadingBookId.value == book['id'],
                        progress: controller.downloadProgress.value,
                        onDownload: () => controller.downloadBook(book['id'] as String),
                        onRemove: () => controller.removeBook(book['id'] as String),
                      ));
                    },
                  ),
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
