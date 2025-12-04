import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/data/book_data_service.dart';
import 'package:chicki_buddy/services/data/vocabulary_data_service.dart';
import 'package:chicki_buddy/ui/screens/flash_card_screen2.dart';
import 'package:chicki_buddy/ui/widgets/vocabulary/add_vocabulary_dialog.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/book.dart';
import '../../models/vocabulary.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late BookDataService bookDataService;
  late VocabularyDataService vocabDataService;
  StreamSubscription? _voiceActionSub;

  List<Vocabulary> vocabs = [];
  bool isLoading = true;

  int get totalVocabs => vocabs.length;
  int get masteredCount => vocabs.where((v) => v.reviewStatus == 'mastered').length;
  int get learningCount => vocabs.where((v) => v.reviewStatus == 'learning' || v.reviewStatus == 'reviewing').length;
  int get newCount => vocabs.where((v) => v.reviewStatus == 'new' || v.reviewStatus == null).length;
  double get progress => totalVocabs > 0 ? (masteredCount / totalVocabs) * 100 : 0;

  @override
  void initState() {
    super.initState();
    bookDataService = Get.find<BookDataService>();
    vocabDataService = Get.find<VocabularyDataService>();
    _loadVocabularies();

    _voiceActionSub = eventBus.stream
        .where((e) => e.type == AppEventType.voiceAction)
        .listen((event) {});
  }

  Future<void> _loadVocabularies() async {
    setState(() => isLoading = true);
    await vocabDataService.loadByBookId(widget.book.id);
    setState(() {
      vocabs = vocabDataService.currentBookVocabs.toList();
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _voiceActionSub?.cancel();
    super.dispose();
  }

  void _startLearning() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashCardScreen2(book: widget.book),
      ),
    );
  }

  Future<void> _showAddVocabDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddVocabularyDialog(
        bookId: widget.book.id,
        onAdded: _loadVocabularies,
      ),
    );

    if (result == true) {
      // Refresh vocab list
      await _loadVocabularies();
    }
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
              title: const Text('Share Book'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Book', style: TextStyle(color: Colors.red)),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Never';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'mastered':
        return Colors.green;
      case 'reviewing':
      case 'learning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusEmoji(String? status) {
    switch (status) {
      case 'mastered':
        return '🟢';
      case 'reviewing':
      case 'learning':
        return '🟡';
      default:
        return '🔴';
    }
  }

  String _getNextReviewText(Vocabulary vocab) {
    if (vocab.nextReviewDate == null) return 'Not reviewed yet';
    final diff = vocab.nextReviewDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Due now';
    if (diff.inHours < 24) return 'In ${diff.inHours}h';
    return 'In ${diff.inDays}d';
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
                                Expanded(
                                  child: Text(
                                    book.title,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
                        // Metadata
                        _buildMetadataCard(),
                        const SizedBox(height: 16),

                        // Progress
                        _buildProgressCard(),
                        const SizedBox(height: 16),

                        // Action buttons
                        _buildActionButtons(),
                        const SizedBox(height: 24),

                        // Vocabulary list
                        Row(
                          children: [
                            const Icon(Icons.list_rounded, color: Colors.blue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'VOCABULARY LIST ($totalVocabs)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            // TODO: Add sort/filter
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (vocabs.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.library_books_outlined,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No vocabularies yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...vocabs.map((vocab) => _buildVocabCard(vocab)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    final book = widget.book;
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          if (book.author != null)
            _buildMetadataRow(Icons.person_rounded, 'Author', book.author!),
          if (book.category != null)
            _buildMetadataRow(Icons.folder_rounded, 'Category', book.category!),
          _buildMetadataRow(Icons.calendar_today_rounded, 'Created', _formatDate(book.createdAt)),
          _buildMetadataRow(Icons.access_time_rounded, 'Last studied', _formatTimeAgo(book.lastOpenedAt)),
          if (book.version != null)
            _buildMetadataRow(Icons.info_outline_rounded, 'Version', book.version!),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
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
                'PROGRESS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem('📚', 'Total', totalVocabs.toString()),
              ),
              Expanded(
                child: _buildStatItem('✅', 'Mastered', masteredCount.toString(), Colors.green),
              ),
              Expanded(
                child: _buildStatItem('📖', 'Learning', learningCount.toString(), Colors.orange),
              ),
              Expanded(
                child: _buildStatItem('🆕', 'New', newCount.toString(), Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, [Color? color]) {
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Start Learning button with gradient
        Container(
          width: double.infinity,
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
              onTap: _startLearning,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'START LEARNING',
                      style: TextStyle(
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddVocabDialog,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'ADD VOCAB',
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
            const SizedBox(width: 12),
            Expanded(
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
        ),
      ],
    );
  }

  Widget _buildVocabCard(Vocabulary vocab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status emoji
          Text(
            _getStatusEmoji(vocab.reviewStatus),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),

          // Word and meaning
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vocab.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vocab.meaning ?? "123",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next review: ${_getNextReviewText(vocab)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Familiarity badge (if available)
          if (vocab.familiarity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(vocab.reviewStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${vocab.familiarity!.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(vocab.reviewStatus),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
