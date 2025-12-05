import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/story_service.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/book.dart';
import '../../models/story_chapter.dart';

class StoryChaptersScreen extends StatefulWidget {
  final Book book;
  const StoryChaptersScreen({super.key, required this.book});

  @override
  State<StoryChaptersScreen> createState() => _StoryChaptersScreenState();
}

class _StoryChaptersScreenState extends State<StoryChaptersScreen> {
  late BookService bookService;
  late StoryService storyService;
  StreamSubscription? _voiceActionSub;

  List<StoryChapter> chapters = [];
  bool isLoading = true;
  StoryChapter? currentChapter;

  // Statistics
  int get totalChapters => chapters.length;
  int get completedChapters => chapters.where((c) => c.isCompleted).length;
  double get overallProgress {
    if (chapters.isEmpty) return 0;
    final totalProgress = chapters.fold<double>(
      0,
      (sum, c) => sum + (c.progressPercent ?? 0),
    );
    return totalProgress / chapters.length;
  }

  int get totalWords => chapters.fold(0, (sum, c) => sum + (c.wordCount ?? 0));
  int get totalReadingTime =>
      chapters.fold(0, (sum, c) => sum + (c.readingTime ?? 0));

  @override
  void initState() {
    super.initState();
    bookService = Get.find<BookService>();
    storyService = Get.find<StoryService>();
    _loadChapters();

    _voiceActionSub = eventBus.stream
        .where((e) => e.type == AppEventType.voiceAction)
        .listen((event) {});
  }

  Future<void> _loadChapters() async {
    setState(() => isLoading = true);
    final loadedChapters =
        storyService.getChaptersByBookIdSorted(widget.book.id);
    final current = storyService.getCurrentReadingChapter(widget.book.id);

    setState(() {
      chapters = loadedChapters;
      currentChapter = current;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _voiceActionSub?.cancel();
    super.dispose();
  }

  void _continueReading() {
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chapters available to read')),
      );
      return;
    }

    // Get current or next unread chapter
    final chapterToRead = currentChapter ??
        storyService.getNextUnreadChapter(widget.book.id) ??
        chapters.first;

    _openChapter(chapterToRead);
  }

  void _openChapter(StoryChapter chapter) {
    // TODO: Navigate to StoryReaderScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Chapter ${chapter.chapterNumber}: ${chapter.title}'),
      ),
    );
  }

  Future<void> _showAddChapterDialog() async {
    // TODO: Implement AddChapterDialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Chapter dialog - Coming soon!')),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Book Info'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded),
              title: const Text('Export as JSON'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement export
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Story'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reset Progress'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement reset with confirmation
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title:
                  const Text('Delete Story', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete with confirmation
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterMenu(StoryChapter chapter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.book_rounded),
              title: const Text('Read Chapter'),
              onTap: () {
                Navigator.pop(context);
                _openChapter(chapter);
              },
            ),
            ListTile(
              leading: Icon(
                chapter.isCompleted
                    ? Icons.radio_button_unchecked_rounded
                    : Icons.check_circle_rounded,
              ),
              title: Text(
                chapter.isCompleted ? 'Mark as Unread' : 'Mark as Completed',
              ),
              onTap: () async {
                Navigator.pop(context);
                if (chapter.isCompleted) {
                  // Reset progress
                  chapter.isCompleted = false;
                  chapter.progressPercent = 0;
                  chapter.lastReadPosition = 0;
                  await storyService.updateChapter(chapter);
                } else {
                  await storyService.markCompleted(chapter);
                }
                _loadChapters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Chapter Info'),
              onTap: () {
                Navigator.pop(context);
                _showChapterInfoDialog(chapter);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Chapter',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete with confirmation
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterInfoDialog(StoryChapter chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chapter ${chapter.chapterNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chapter.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (chapter.summary != null) ...[
                const Text(
                  'Summary:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(chapter.summary!),
                const SizedBox(height: 12),
              ],
              _buildInfoRow('Word Count', '${chapter.wordCount ?? "N/A"}'),
              _buildInfoRow('Reading Time', '${chapter.readingTime ?? 0} min'),
              _buildInfoRow(
                  'Progress', '${chapter.progressPercent?.toStringAsFixed(1) ?? 0}%'),
              _buildInfoRow('Status',
                  chapter.isCompleted ? 'Completed ✅' : 'In Progress 📖'),
              if (chapter.lastReadAt != null)
                _buildInfoRow('Last Read', _formatDate(chapter.lastReadAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Not started';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header with book info
          Stack(
            children: [
              Hero(
                tag: 'book_${book.id}',
                child: Material(
                  color: Colors.transparent,
                  child: RandomGradient(
                    book.id,
                    seed: "bookCardGradient",
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      if (book.author != null)
                                        Text(
                                          'by ${book.author}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert,
                                        color: Colors.white),
                                    onPressed: _showMoreMenu,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AutoSizeText(
                              book.description,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 56,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Card
                        _buildStatisticsCard(),
                        const SizedBox(height: 16),

                        // Action buttons
                        _buildActionButtons(),
                        const SizedBox(height: 24),

                        // Chapters list header
                        Row(
                          children: [
                            const Icon(Icons.list_rounded,
                                color: Colors.blue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'CHAPTERS ($totalChapters)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Empty state
                        if (chapters.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.menu_book_outlined,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No chapters yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to add your first chapter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...chapters.map((chapter) => _buildChapterCard(chapter)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChapterDialog,
        backgroundColor: Colors.blue.shade600,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'ADD CHAPTER',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Text(
                'READING PROGRESS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${overallProgress.toStringAsFixed(1)}% Complete',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem('📖', 'Chapters', totalChapters.toString()),
              ),
              Expanded(
                child: _buildStatItem(
                    '✅', 'Completed', completedChapters.toString(), Colors.green),
              ),
              Expanded(
                child: _buildStatItem('📝', 'Words', _formatNumber(totalWords)),
              ),
              Expanded(
                child: _buildStatItem(
                    '⏱️', 'Time', '${totalReadingTime}m', Colors.orange),
              ),
            ],
          ),

          // Current chapter indicator
          if (currentChapter != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bookmark_rounded,
                    color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currently Reading',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Chapter ${currentChapter!.chapterNumber}: ${currentChapter!.title}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value,
      [Color? color]) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _continueReading,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        currentChapter != null ? 'CONTINUE READING' : 'START READING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Export
            },
            icon: const Icon(Icons.file_download_rounded, size: 20),
            label: const Text(
              'EXPORT',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterCard(StoryChapter chapter) {
    final isCurrentChapter = currentChapter?.id == chapter.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentChapter
            ? Border.all(color: Colors.blue.shade400, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openChapter(chapter),
          onLongPress: () => _showChapterMenu(chapter),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Chapter number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: chapter.isCompleted
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: chapter.isCompleted
                              ? Colors.green.shade300
                              : Colors.blue.shade300,
                        ),
                      ),
                      child: Text(
                        '${chapter.chapterNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: chapter.isCompleted
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (chapter.wordCount != null ||
                              chapter.readingTime != null)
                            const SizedBox(height: 4),
                          Row(
                            children: [
                              if (chapter.wordCount != null) ...[
                                Icon(Icons.text_fields_rounded,
                                    size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${chapter.wordCount} words',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              if (chapter.readingTime != null) ...[
                                if (chapter.wordCount != null) ...[
                                  const SizedBox(width: 8),
                                  Text('•',
                                      style:
                                          TextStyle(color: Colors.grey.shade400)),
                                  const SizedBox(width: 8),
                                ],
                                Icon(Icons.access_time_rounded,
                                    size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${chapter.readingTime} min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status icon
                    if (chapter.isCompleted)
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 24)
                    else if (isCurrentChapter)
                      Icon(Icons.bookmark_rounded,
                          color: Colors.blue.shade600, size: 24)
                    else if ((chapter.progressPercent ?? 0) > 0)
                      Icon(Icons.play_circle_outline_rounded,
                          color: Colors.orange.shade600, size: 24),
                  ],
                ),

                // Summary
                if (chapter.summary != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    chapter.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],

                // Progress bar (if started)
                if ((chapter.progressPercent ?? 0) > 0 && !chapter.isCompleted) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${chapter.progressPercent!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: chapter.progressPercent! / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange.shade400),
                        ),
                      ),
                    ],
                  ),
                ],

                // Last read indicator
                if (chapter.lastReadAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Last read ${_formatTimeAgo(chapter.lastReadAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
