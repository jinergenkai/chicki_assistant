import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BookCard extends StatefulWidget {
  final String id;
  final String title;
  final String desc;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  // New fields for enhanced display
  final int? totalVocabs;
  final int? masteredVocabs;
  final DateTime? lastOpenedAt;
  final String? category;

  const BookCard({
    super.key,
    required this.id,
    required this.title,
    required this.desc,
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
    required this.onRemove,
    this.totalVocabs,
    this.masteredVocabs,
    this.lastOpenedAt,
    this.category,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  double get learningProgress {
    if (widget.totalVocabs == null || widget.totalVocabs == 0) return 0;
    return (widget.masteredVocabs ?? 0) / widget.totalVocabs!;
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 180.0;
    const cardHeight = cardWidth * 1.5;
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient background
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                children: [
                  RandomGradient(
                    widget.id,
                    seed: "bookCardGradient",
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category badge (top left)
          if (widget.category != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.category!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

          // Bookmark icon (top right)
          const Positioned(
            top: 12,
            right: 12,
            child: Icon(
              LucideIcons.bookmark,
              color: Colors.white,
              size: 20,
            ),
          ),

          // Card content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Description
                  AutoSizeText(
                    widget.desc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Stats section
                  if (widget.totalVocabs != null) ...[
                    // Vocab count
                    Row(
                      children: [
                        const Icon(
                          Icons.library_books_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.totalVocabs} words',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Learning progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${(learningProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: learningProgress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Last studied time
                  if (widget.lastOpenedAt != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(widget.lastOpenedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Download progress (if downloading)
                  if (widget.isDownloading)
                    MoonLinearProgress(
                      value: widget.progress,
                      linearProgressSize: MoonLinearProgressSize.x4s,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),

                  // Action button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MoonButton.icon(
                        icon: widget.isDownloaded
                            ? const Icon(LucideIcons.trash, color: Colors.red)
                            : const Icon(LucideIcons.download, color: Colors.amber),
                        onTap: widget.isDownloaded ? widget.onRemove : widget.onDownload,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
