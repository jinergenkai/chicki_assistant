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
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
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
          // Placeholder colorful image with blur
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                children: [
                  // Image.asset(
                  //   'assets/overlay.jpg',
                  //   fit: BoxFit.cover,
                  //   width: cardWidth,
                  //   height: cardHeight,
                  // ),
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
          // Bookmark icon top right
          const Positioned(
            top: 12,
            right: 12,
            child: Icon(
              LucideIcons.bookmark,
              color: Colors.black,
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
                  AutoSizeText(
                    widget.desc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (widget.isDownloading)
                    MoonLinearProgress(
                      value: widget.progress,
                      linearProgressSize: MoonLinearProgressSize.x4s,
                      backgroundColor: Colors.white24,
                      color: Colors.black,
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MoonButton.icon(
                        icon: widget.isDownloaded ? const Icon(LucideIcons.trash, color: Colors.red) : const Icon(LucideIcons.download, color: Colors.amber),
                        onTap: widget.isDownloaded ? widget.onRemove : widget.onDownload,
                        // size: MoonIconButtonSize.xs,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        // tooltip: isDownloaded ? 'Remove' : 'Download',
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
