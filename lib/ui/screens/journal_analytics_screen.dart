import 'package:chicki_buddy/models/journal_entry.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class JournalAnalyticsScreen extends StatefulWidget {
  final String bookId;

  const JournalAnalyticsScreen({super.key, required this.bookId});

  @override
  State<JournalAnalyticsScreen> createState() => _JournalAnalyticsScreenState();
}

class _JournalAnalyticsScreenState extends State<JournalAnalyticsScreen> {
  late JournalService journalService;
  List<JournalEntry> entries = [];
  String selectedPeriod = '30d'; // 7d, 30d, 90d, all

  @override
  void initState() {
    super.initState();
    journalService = Get.find<JournalService>();
    _loadEntries();
  }

  void _loadEntries() {
    setState(() {
      entries = journalService.getEntriesByBookIdSorted(widget.bookId);
    });
  }

  List<JournalEntry> _getFilteredEntries() {
    if (selectedPeriod == 'all') return entries;

    final now = DateTime.now();
    int days;
    switch (selectedPeriod) {
      case '7d':
        days = 7;
        break;
      case '30d':
        days = 30;
        break;
      case '90d':
        days = 90;
        break;
      default:
        return entries;
    }

    final cutoffDate = now.subtract(Duration(days: days));
    return entries.where((e) => e.date.isAfter(cutoffDate)).toList();
  }

  Map<String, int> _getMoodDistribution() {
    final filtered = _getFilteredEntries();
    Map<String, int> distribution = {};

    for (var entry in filtered) {
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        distribution[entry.mood!] = (distribution[entry.mood!] ?? 0) + 1;
      }
    }

    return distribution;
  }

  Map<String, int> _getWritingStreak() {
    final filtered = _getFilteredEntries()..sort((a, b) => a.date.compareTo(b.date));
    Map<String, int> dailyCount = {};

    for (var entry in filtered) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
      dailyCount[dateKey] = (dailyCount[dateKey] ?? 0) + 1;
    }

    return dailyCount;
  }

  int _getCurrentStreak() {
    final sorted = entries..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (var entry in sorted) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final checkDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

      if (entryDate == checkDate || entryDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        currentDate = entry.date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Color _getMoodColor(String mood) {
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
    final filtered = _getFilteredEntries();
    final moodDist = _getMoodDistribution();
    final totalEntries = filtered.length;
    final totalWords = filtered.fold<int>(0, (sum, e) => sum + (e.wordCount ?? 0));
    final avgWords = totalEntries > 0 ? (totalWords / totalEntries).round() : 0;
    final currentStreak = _getCurrentStreak();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Journal Analytics',
          style: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            Container(
              padding: const EdgeInsets.all(4),
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
              child: Row(
                children: [
                  _buildPeriodChip('7d', '7 Days'),
                  _buildPeriodChip('30d', '30 Days'),
                  _buildPeriodChip('90d', '90 Days'),
                  _buildPeriodChip('all', 'All Time'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.auto_stories_outlined,
                    label: 'Entries',
                    value: totalEntries.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '$currentStreak days',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.text_fields_rounded,
                    label: 'Total Words',
                    value: totalWords.toString(),
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.analytics_outlined,
                    label: 'Avg/Entry',
                    value: '$avgWords words',
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Mood Distribution
            Text(
              'Mood Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16),

            if (moodDist.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.mood_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No mood data yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    // Bar chart
                    _buildMoodBarChart(moodDist, totalEntries),
                    const SizedBox(height: 24),

                    // Mood breakdown
                    ...moodDist.entries.map((entry) {
                      final percentage = (entry.value / totalEntries * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getMoodColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value} ($percentage%)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Writing activity heatmap
            Text(
              'Writing Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildActivityHeatmap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = selectedPeriod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedPeriod = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBarChart(Map<String, int> moodDist, int total) {
    final maxCount = moodDist.values.reduce((a, b) => a > b ? a : b);
    final sortedEntries = moodDist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        final percentage = entry.value / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMoodColor(entry.key),
                              _getMoodColor(entry.key).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityHeatmap() {
    final writingStreak = _getWritingStreak();
    if (writingStreak.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No writing activity yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Get last 7 weeks
    final now = DateTime.now();
    List<Widget> weekRows = [];

    for (int week = 6; week >= 0; week--) {
      List<Widget> dayBoxes = [];
      for (int day = 0; day < 7; day++) {
        final date = now.subtract(Duration(days: week * 7 + (6 - day)));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final count = writingStreak[dateKey] ?? 0;

        dayBoxes.add(
          Tooltip(
            message: '$dateKey: $count ${count == 1 ? 'entry' : 'entries'}',
            child: Container(
              margin: const EdgeInsets.all(2),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: count == 0
                    ? Colors.grey.shade200
                    : Colors.blue.shade600.withOpacity(0.2 + (count / 5).clamp(0.0, 0.8)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: count > 0 ? Colors.blue.shade600 : Colors.grey.shade300,
                  width: count > 0 ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: count > 0
                    ? Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: count > 2 ? Colors.white : Colors.blue.shade900,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      }
      weekRows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dayBoxes,
      ));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ...weekRows,
      ],
    );
  }
}
