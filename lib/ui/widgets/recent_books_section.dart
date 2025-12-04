import 'package:flutter/material.dart';
import '../../models/book.dart';

class RecentBooksSection extends StatelessWidget {
  final List<Book> recentBooks;
  final Function(Book) onBookTap;
  final VoidCallback? onSeeAll;

  const RecentBooksSection({
    super.key,
    required this.recentBooks,
    required this.onBookTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Colors.blue,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'RECENT BOOKS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See All'),
                ),
            ],
          ),
        ),

        // Horizontal scroll list
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recentBooks.length,
            itemBuilder: (context, index) {
              final book = recentBooks[index];
              return _buildRecentBookCard(book, context);
            },
          ),
        ),

        const SizedBox(height: 16),
        const Divider(thickness: 1, height: 1),
      ],
    );
  }

  Widget _buildRecentBookCard(Book book, BuildContext context) {
    final lastOpened = book.lastOpenedAt;
    String timeAgo = '';
    if (lastOpened != null) {
      final difference = DateTime.now().difference(lastOpened);
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        timeAgo = '${difference.inDays}d ago';
      } else {
        timeAgo = '${(difference.inDays / 7).floor()}w ago';
      }
    }

    return GestureDetector(
      onTap: () => onBookTap(book),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover/icon
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getGradientColor(book.id, 0),
                    _getGradientColor(book.id, 1),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Icon(
                  book.isCustom ? Icons.bookmark_rounded : Icons.book_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),

            // Book info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Time ago
                    if (timeAgo.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate gradient colors based on book ID
  Color _getGradientColor(String bookId, int index) {
    final hash = bookId.hashCode;
    final colors = [
      [Colors.blue.shade400, Colors.blue.shade600],
      [Colors.purple.shade400, Colors.purple.shade600],
      [Colors.green.shade400, Colors.green.shade600],
      [Colors.orange.shade400, Colors.orange.shade600],
      [Colors.pink.shade400, Colors.pink.shade600],
      [Colors.teal.shade400, Colors.teal.shade600],
    ];
    final colorPair = colors[hash.abs() % colors.length];
    return colorPair[index];
  }
}
