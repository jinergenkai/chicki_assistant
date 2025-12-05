import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/ui/screens/flash_card_screen2.dart';
import 'package:chicki_buddy/ui/screens/journal_entries_screen.dart';
import 'package:chicki_buddy/ui/screens/story_chapters_screen.dart';
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
  late BookService bookService;
  late VocabularyService vocabService;
  StreamSubscription? _voiceActionSub;
  bool _hasNavigated = false;

  List<Vocabulary> vocabs = [];
  List<Vocabulary> filteredVocabs = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedStatusFilter;
  int? selectedDifficultyFilter;

  int get totalVocabs => vocabs.length;
  int get masteredCount => vocabs.where((v) => v.reviewStatus == 'mastered').length;
  int get learningCount => vocabs.where((v) => v.reviewStatus == 'learning' || v.reviewStatus == 'reviewing').length;
  int get newCount => vocabs.where((v) => v.reviewStatus == 'new' || v.reviewStatus == null).length;
  double get progress => totalVocabs > 0 ? (masteredCount / totalVocabs) * 100 : 0;

  @override
  void initState() {
    super.initState();
    bookService = Get.find<BookService>();
    vocabService = Get.find<VocabularyService>();

    // Route to appropriate screen based on book type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToBookType();
    });

    _loadVocabularies();

    _voiceActionSub = eventBus.stream
        .where((e) => e.type == AppEventType.voiceAction)
        .listen((event) {});
  }

  void _navigateToBookType() {
    if (_hasNavigated) return;

    final book = widget.book;

    switch (book.type) {
      case BookType.journal:
        _hasNavigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => JournalEntriesScreen(book: book),
          ),
        );
        break;
      case BookType.story:
        _hasNavigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StoryChaptersScreen(book: book),
          ),
        );
        break;
      case BookType.flashBook:
        // Stay on current screen (default vocabulary behavior)
        break;
    }
  }

  Future<void> _loadVocabularies() async {
    setState(() => isLoading = true);
    final loadedVocabs = vocabService.getByBookIdSorted(widget.book.id);
    setState(() {
      vocabs = loadedVocabs;
      _applyFilters();
      isLoading = false;
    });
  }

  void _applyFilters() {
    filteredVocabs = vocabs.where((vocab) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesWord = vocab.word.toLowerCase().contains(query);
        final matchesMeaning = (vocab.meaning ?? '').toLowerCase().contains(query);
        final matchesTopic = (vocab.topic ?? '').toLowerCase().contains(query);
        if (!matchesWord && !matchesMeaning && !matchesTopic) {
          return false;
        }
      }

      // Status filter
      if (selectedStatusFilter != null) {
        if (selectedStatusFilter == 'new' &&
            vocab.reviewStatus != null &&
            vocab.reviewStatus != 'new') {
          return false;
        } else if (selectedStatusFilter != 'new' &&
                   vocab.reviewStatus != selectedStatusFilter) {
          return false;
        }
      }

      // Difficulty filter
      if (selectedDifficultyFilter != null &&
          vocab.difficulty != selectedDifficultyFilter) {
        return false;
      }

      return true;
    }).toList();
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

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Vocabulary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Status Filter
              const Text('Review Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedStatusFilter == null,
                    onSelected: (selected) {
                      setState(() {
                        selectedStatusFilter = null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('🔴 New')],
                    ),
                    selected: selectedStatusFilter == 'new',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatusFilter = selected ? 'new' : null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('🟡 Learning')],
                    ),
                    selected: selectedStatusFilter == 'learning',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatusFilter = selected ? 'learning' : null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('🟢 Mastered')],
                    ),
                    selected: selectedStatusFilter == 'mastered',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatusFilter = selected ? 'mastered' : null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Difficulty Filter
              const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(6, (index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: const Text('All'),
                      selected: selectedDifficultyFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          selectedDifficultyFilter = null;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    );
                  }
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(index, (_) =>
                        const Icon(Icons.star, size: 14, color: Colors.amber)
                      ),
                    ),
                    selected: selectedDifficultyFilter == index,
                    onSelected: (selected) {
                      setState(() {
                        selectedDifficultyFilter = selected ? index : null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
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

                        // Search and Filter
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                    _applyFilters();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search vocabulary...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: (selectedStatusFilter != null ||
                                        selectedDifficultyFilter != null)
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: (selectedStatusFilter != null ||
                                        selectedDifficultyFilter != null)
                                    ? Border.all(color: Colors.blue.shade400, width: 2)
                                    : null,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.filter_list_rounded),
                                onPressed: _showFilterMenu,
                                tooltip: 'Filter',
                                color: (selectedStatusFilter != null ||
                                        selectedDifficultyFilter != null)
                                    ? Colors.blue.shade700
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Active filters display
                        if (selectedStatusFilter != null ||
                            selectedDifficultyFilter != null ||
                            searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (searchQuery.isNotEmpty)
                                  Chip(
                                    label: Text('Search: "$searchQuery"'),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                if (selectedStatusFilter != null)
                                  Chip(
                                    label: Text('Status: $selectedStatusFilter'),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        selectedStatusFilter = null;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                if (selectedDifficultyFilter != null)
                                  Chip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Difficulty: '),
                                        ...List.generate(
                                          selectedDifficultyFilter!,
                                          (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                                        ),
                                      ],
                                    ),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        selectedDifficultyFilter = null;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),

                        // Vocabulary list header
                        Row(
                          children: [
                            const Icon(Icons.list_rounded, color: Colors.blue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'VOCABULARY (${filteredVocabs.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (filteredVocabs.isEmpty && vocabs.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No vocabulary matches your filters',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (vocabs.isEmpty)
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
                          ...filteredVocabs.map((vocab) => _buildVocabCard(vocab)),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // TODO: Show vocab detail dialog or navigate to detail screen
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with status and difficulty
                Row(
                  children: [
                    // Status indicator with background
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vocab.reviewStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getStatusEmoji(vocab.reviewStatus),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Word
                    Expanded(
                      child: Text(
                        vocab.word,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Difficulty stars
                    if (vocab.difficulty != null && vocab.difficulty! > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          vocab.difficulty!,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Meaning
                Text(
                  vocab.meaning ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Example sentence
                if (vocab.exampleSentence != null && vocab.exampleSentence!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vocab.exampleSentence!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom info row
                Row(
                  children: [
                    // Topic tag
                    if (vocab.topic != null && vocab.topic!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vocab.topic!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Next review info
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getNextReviewText(vocab),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Familiarity badge
                    if (vocab.familiarity != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(vocab.reviewStatus).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(vocab.reviewStatus).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 12,
                              color: _getStatusColor(vocab.reviewStatus),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${vocab.familiarity!.toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(vocab.reviewStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
