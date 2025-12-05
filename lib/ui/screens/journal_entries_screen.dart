import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:chicki_buddy/ui/screens/journal_entry_detail_screen.dart';
import 'package:chicki_buddy/ui/screens/add_journal_entry_screen.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  StreamSubscription? _voiceActionSub;

  List<JournalEntry> entries = [];
  List<JournalEntry> filteredEntries = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedMoodFilter;
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

      return true;
    }).toList();
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
                // TODO: Implement calendar view
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
        return '😊';
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
      body: Column(
        children: [
          // Minimalist Header
          Hero(
            tag: 'book_${book.id}',
            child: Material(
              color: Colors.transparent,
              child: RandomGradient(
                book.id,
                seed: "bookCardGradient",
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: _showMoreMenu,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEntries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                entries.isEmpty ? Icons.auto_stories_outlined : Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                entries.isEmpty ? 'Bắt đầu hành trình của bạn' : 'Không tìm thấy entries',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entriesByDate.length,
                        itemBuilder: (context, index) {
                          String dateKey = entriesByDate.keys.elementAt(index);
                          List<JournalEntry> dayEntries = entriesByDate[dateKey]!;
                          DateTime date = dayEntries.first.date;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Modern Date Header
                              Padding(
                                padding: EdgeInsets.only(bottom: 16, top: (index == 0 ? 0 : 28)),
                                child: Row(
                                  children: [
                                    // Date Card (Day + Month)
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _formatDayNumber(date),
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade900,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatMonthShort(date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Weekday + Relative Time
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatWeekday(date),
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade900,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatRelativeDate(date),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Entries for this date
                              ...dayEntries.map((entry) => _buildEntryCard(entry)),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddEntryDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + Title + Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar (User circle)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/avatar/dog.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(entry.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Favorite star
                    if (entry.isFavorite)
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Content preview
                Text(
                  entry.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                ),

                // Tags and metadata row
                if (entry.tags != null && entry.tags!.isNotEmpty || entry.wordCount != null || entry.mood != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Mood badge
                      if (entry.mood != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getMoodColor(entry.mood).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getMoodColor(entry.mood).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getMoodEmoji(entry.mood),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.mood!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getMoodColor(entry.mood),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Word count
                      if (entry.wordCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.text_fields_rounded,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.wordCount} words',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Tags
                      if (entry.tags != null && entry.tags!.isNotEmpty)
                        ...entry.tags!.take(3).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
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
