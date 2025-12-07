import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/book.dart';

class BookCard extends StatefulWidget {
  final String id;
  final String title;
  final String desc;
  // REMOVED: Download/Progress fields
  
  // New fields for enhanced display
  final BookType type;
  final int? totalVocabs;
  final int? masteredVocabs;
  final int? journalEntryCount; // For Journal type
  final DateTime? lastOpenedAt;
  
  // Custom dimensions
  final double? width;
  final double? height;
  final String? coverId;


  const BookCard({
    super.key,
    required this.id,
    required this.title,
    required this.desc,
    required this.type,
    this.totalVocabs,
    this.masteredVocabs,
    this.journalEntryCount,
    this.lastOpenedAt,
    this.width,
    this.height,
    this.coverId,
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

  String get _typeLabel {
    switch (widget.type) {
      case BookType.flashBook: return 'Flashcard';
      case BookType.journal: return 'Journal';
      case BookType.story: return 'Story';
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case BookType.flashBook: return Colors.blue.shade600;
      case BookType.journal: return Colors.amber.shade600;
      case BookType.story: return Colors.purple.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 180.0;
    final cardHeight = widget.height ?? (cardWidth * 1.5);
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Softened shadow
            blurRadius: 12, // Reduced blur
            spreadRadius: 1,
            offset: const Offset(0, 4), // Reduced offset
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
                    widget.coverId ?? widget.id,
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

          // Type badge (top left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset:const Offset(0,2))
                ]
              ),
              child: Row(
                children: [
                   Container(
                     width: 6, height: 6,
                     decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle),
                   ),
                   const SizedBox(width: 6),
                   Text(
                    _typeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.2
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bookmark icon (top right) - kept for visual balance
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
                  const SizedBox(height: 20), // Spacing for badge

                  const Spacer(),

                  // Title
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          height: 1.2
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  AutoSizeText(
                    widget.desc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),

                  // Stats section - TYPE SPECIFIC
                  if (widget.type == BookType.flashBook && widget.totalVocabs != null) ...[
                    // Vocab count
                    Row(
                      children: [
                        Icon(LucideIcons.graduationCap, color: Colors.white.withOpacity(0.9), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.totalVocabs} words',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: learningProgress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ] else if (widget.type == BookType.journal && widget.journalEntryCount != null) ...[
                    // Entry count
                     Row(
                      children: [
                        Icon(LucideIcons.pencil, color: Colors.white.withOpacity(0.9), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.journalEntryCount} entries',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                     const SizedBox(height: 12), // Visual balance
                  ],

                  // Last studied time
                  if (widget.lastOpenedAt != null) ...[
                     const SizedBox(height: 8),
                     Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          color: Colors.white.withOpacity(0.7),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(widget.lastOpenedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
