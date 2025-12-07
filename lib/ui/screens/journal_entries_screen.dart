import 'dart:async';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:chicki_buddy/services/attachment_service.dart';
import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/ui/screens/journal_entry_detail_screen.dart';
import 'package:chicki_buddy/ui/screens/add_journal_entry_screen.dart';
import 'package:chicki_buddy/ui/screens/journal_analytics_screen.dart';
import 'package:chicki_buddy/ui/widgets/journal/calendar_month_view.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/zondicons.dart';
import 'package:intl/intl.dart';
import '../../models/book.dart';
import '../../models/journal_entry.dart';

class JournalEntriesScreen extends StatefulWidget {
  final Book book;
  const JournalEntriesScreen({super.key, required this.book});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  late BookService bookService;
  late JournalService journalService;
  final AttachmentService _attachmentService = AttachmentService();
  StreamSubscription? _voiceActionSub;

  List<JournalEntry> entries = [];
  List<JournalEntry> filteredEntries = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedMoodFilter;
  DateTime? selectedDate;
  bool sortAscending = false; // Default: newest first

  // Statistics
  int get totalEntries => entries.length;
  int get totalWords => entries.fold(0, (sum, e) => sum + (e.wordCount ?? 0));
  int get avgWordsPerEntry => totalEntries > 0 ? (totalWords / totalEntries).round() : 0;
  Map<String, int> get moodDistribution {
    final Map<String, int> dist = {};
    for (var entry in entries) {
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        dist[entry.mood!] = (dist[entry.mood!] ?? 0) + 1;
      }
    }
    return dist;
  }

  @override
  void initState() {
    super.initState();
    bookService = Get.find<BookService>();
    journalService = Get.find<JournalService>();
    _loadEntries();

    _voiceActionSub = eventBus.stream.where((e) => e.type == AppEventType.voiceAction).listen((event) {});
  }

  Future<void> _loadEntries() async {
    setState(() => isLoading = true);
    final loadedEntries = journalService.getEntriesByBookIdSorted(
      widget.book.id,
      ascending: sortAscending,
    );
    setState(() {
      entries = loadedEntries;
      _applyFilters();
      isLoading = false;
    });
  }

  void _applyFilters() {
    filteredEntries = entries.where((entry) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = entry.title.toLowerCase().contains(query);
        final matchesContent = entry.content.toLowerCase().contains(query);
        final matchesTags = entry.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false;
        if (!matchesTitle && !matchesContent && !matchesTags) {
          return false;
        }
      }

      // Mood filter
      if (selectedMoodFilter != null && entry.mood != selectedMoodFilter) {
        return false;
      }

      // Date filter
      if (selectedDate != null) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final filterDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        if (entryDate != filterDate) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: CalendarMonthView(
                    entries: entries,
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalAnalyticsScreen(bookId: widget.book.id),
      ),
    );
  }

  @override
  void dispose() {
    _voiceActionSub?.cancel();
    super.dispose();
  }

  Future<void> _showAddEntryDialog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddJournalEntryScreen(
          bookId: widget.book.id,
          onSaved: _loadEntries,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      await _loadEntries();
    }
  }

  void _toggleSortOrder() {
    setState(() {
      sortAscending = !sortAscending;
      entries = journalService.getEntriesByBookIdSorted(
        widget.book.id,
        ascending: sortAscending,
      );
      _applyFilters();
    });
  }

  void _showFilterMenu() {
    final moods = moodDistribution.keys.toList()..sort();

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
                'Filter by Mood',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // All moods option
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedMoodFilter == null,
                    onSelected: (selected) {
                      setState(() {
                        selectedMoodFilter = null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  // Individual mood filters
                  ...moods.map((mood) => ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getMoodEmoji(mood)),
                            const SizedBox(width: 6),
                            Text(mood),
                          ],
                        ),
                        selected: selectedMoodFilter == mood,
                        onSelected: (selected) {
                          setState(() {
                            selectedMoodFilter = selected ? mood : null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                      )),
                ],
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
              title: const Text('Share Journal'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Calendar View'),
              onTap: () {
                Navigator.pop(context);
                _showCalendar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showAnalytics();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Journal', style: TextStyle(color: Colors.red)),
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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays} days ago';
    } else if (now.difference(date).inDays < 30) {
      int weeks = (now.difference(date).inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (now.difference(date).inDays < 365) {
      int months = (now.difference(date).inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      int years = (now.difference(date).inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  String _formatDayNumber(DateTime date) {
    return DateFormat('d').format(date);
  }

  String _formatMonthShort(DateTime date) {
    return DateFormat('MMM').format(date).toUpperCase();
  }

  String _formatWeekday(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  String _getMoodEmoji(String? mood) {
    if (mood == null) return '📝';
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return '(˶ᵔ ᵕ ᵔ˶)';
      case 'sad':
      case 'down':
      case 'depressed':
        return '😢';
      case 'angry':
      case 'frustrated':
        return '😠';
      case 'anxious':
      case 'worried':
        return '😰';
      case 'calm':
      case 'peaceful':
        return '😌';
      case 'grateful':
      case 'thankful':
        return '🙏';
      case 'hopeful':
      case 'optimistic':
        return '🌟';
      case 'accomplished':
      case 'proud':
        return '🎯';
      case 'neutral':
        return '😐';
      default:
        return '📝';
    }
  }

  Color _getMoodColor(String? mood) {
    if (mood == null) return Colors.grey;
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
      case 'grateful':
      case 'hopeful':
      case 'accomplished':
        return Colors.green;
      case 'sad':
      case 'down':
      case 'depressed':
        return Colors.blue;
      case 'angry':
      case 'frustrated':
        return Colors.red;
      case 'anxious':
      case 'worried':
        return Colors.orange;
      case 'calm':
      case 'peaceful':
        return Colors.teal;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    // Group entries by date
    Map<String, List<JournalEntry>> entriesByDate = {};
    for (var entry in filteredEntries) {
      String dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
      if (!entriesByDate.containsKey(dateKey)) {
        entriesByDate[dateKey] = [];
      }
      entriesByDate[dateKey]!.add(entry);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredEntries.isEmpty
              ? Column(
                  children: [
                    // Simple header without gradient
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.grey.shade800, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              book.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert, color: Colors.grey.shade800),
                            onPressed: _showMoreMenu,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                entries.isEmpty
                                    ? Icons.auto_stories_outlined
                                    : Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                entries.isEmpty
                                    ? 'Start your first journal'
                                    : 'No entries found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    // Clean modern AppBar
                    SliverAppBar(
                      pinned: true,
                      elevation: 0,
                      toolbarHeight: 70,
                      backgroundColor: Colors.grey.shade50,
                      surfaceTintColor: Colors.transparent, // Disable material 3 tint
                      centerTitle: false,
                      titleSpacing: 0,
                      leadingWidth: 70,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.more_horiz_rounded, color: Colors.black87),
                              onPressed: _showMoreMenu,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Spacing between topbar and content
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 12),
                    ),

                    // Sticky date headers with entries
                    ...entriesByDate.entries.map((dateEntry) {
                      final dateKey = dateEntry.key;
                      final dayEntries = dateEntry.value;
                      final date = dayEntries.first.date;

                      return SliverMainAxisGroup(
                        slivers: [
                          // Sticky date header
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyDateHeaderDelegate(
                              date: date,
                              formatDayNumber: _formatDayNumber,
                              formatMonthShort: _formatMonthShort,
                              formatWeekday: _formatWeekday,
                              formatRelativeDate: _formatRelativeDate,
                            ),
                          ),
                          // Entries for this date
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildEntryCard(dayEntries[index]),
                                childCount: dayEntries.length,
                              ),
                            ),
                          ),
                          // Spacing after entries
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 16),
                          ),
                        ],
                      );
                    }),

                    // Bottom padding for FAB
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blue.shade500, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddEntryDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Iconify(Ri.quill_pen_line, color: Colors.white, size: 32),
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
                'JOURNAL STATISTICS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem('📝', 'Entries', totalEntries.toString()),
              ),
              Expanded(
                child: _buildStatItem('📊', 'Total Words', totalWords.toString()),
              ),
              Expanded(
                child: _buildStatItem('✍️', 'Avg/Entry', avgWordsPerEntry.toString()),
              ),
            ],
          ),

          // Mood distribution
          if (moodDistribution.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'MOOD DISTRIBUTION',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moodDistribution.entries
                  .map((e) => Chip(
                        avatar: Text(_getMoodEmoji(e.key)),
                        label: Text('${e.key}: ${e.value}'),
                        backgroundColor: _getMoodColor(e.key).withOpacity(0.1),
                        side: BorderSide(
                          color: _getMoodColor(e.key).withOpacity(0.3),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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
                onTap: _showAddEntryDialog,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'NEW ENTRY',
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

  Widget _buildEntryCard(JournalEntry entry) {
    final appConfig = Get.find<AppConfigController>();
    final photoPaths = _attachmentService.getPhotoPaths(entry.attachments);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JournalEntryDetailScreen(
                  entry: entry,
                  onChanged: _loadEntries,
                ),
              ),
            );
            _loadEntries();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User Avatar
                    Obx(() {
                       final avatarId = appConfig.userAvatar.value;
                       final avatarPath = avatarId.isNotEmpty
                           ? 'assets/avatar/$avatarId.png'
                           : 'assets/avatar/dog.png';
                       
                       return CircleAvatar(
                         radius: 18,
                         backgroundColor: Colors.transparent,
                         child: ClipOval(
                           child: Image.asset(
                             avatarPath,
                             width: 36,
                             height: 36,
                             fit: BoxFit.cover,
                             errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/avatar/dog.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                );
                             },
                           ),
                         ),
                       );
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                _formatTime(entry.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (entry.mood != null) ...[
                                 const SizedBox(width: 8),
                                 Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                                 const SizedBox(width: 8),
                                 Text(_getMoodEmoji(entry.mood), style: const TextStyle(fontSize: 14)),
                              ]
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content preview
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),

                // Photo Preview (Horizontal Scroll)
                if (photoPaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoPaths.length,
                      separatorBuilder: (_,__) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photoPaths[index]),
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Tags (Badge Style)
                if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.tags!.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getTagIcon(tag), size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600
                            ),
                          )
                        ],
                      ),
                    )).toList(),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTagIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'work': return Icons.work_rounded;
      case 'family': return Icons.family_restroom_rounded;
      case 'friends': return Icons.groups_rounded;
      case 'school': return Icons.school_rounded;
      case 'travel': return Icons.flight_takeoff_rounded;
      case 'food': return Icons.restaurant_rounded;
      case 'exercise': return Icons.fitness_center_rounded;
      case 'hobbies': return Icons.palette_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'weather': return Icons.wb_sunny_rounded;
      case 'relaxing': return Icons.spa_rounded;
      default: return Icons.label_outline_rounded;
    }
  }
}

// Sticky Date Header Delegate
class _StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;
  final String Function(DateTime) formatDayNumber;
  final String Function(DateTime) formatMonthShort;
  final String Function(DateTime) formatWeekday;
  final String Function(DateTime) formatRelativeDate;

  _StickyDateHeaderDelegate({
    required this.date,
    required this.formatDayNumber,
    required this.formatMonthShort,
    required this.formatWeekday,
    required this.formatRelativeDate,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? Colors.grey.shade200 : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          // Minimal date badge
          Text(
            formatDayNumber(date),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMonthShort(date),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatWeekday(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            formatRelativeDate(date),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyDateHeaderDelegate oldDelegate) {
    return date != oldDelegate.date;
  }
}
