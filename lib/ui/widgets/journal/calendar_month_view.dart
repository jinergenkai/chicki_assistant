import 'package:chicki_buddy/models/journal_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarMonthView extends StatefulWidget {
  final List<JournalEntry> entries;
  final DateTime? selectedDate;
  final Function(DateTime?)? onDateSelected;

  const CalendarMonthView({
    super.key,
    required this.entries,
    this.selectedDate,
    this.onDateSelected,
  });

  @override
  State<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends State<CalendarMonthView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = widget.selectedDate;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
      _selectedDate = null;
      widget.onDateSelected?.call(null);
    });
  }

  List<JournalEntry> _getEntriesForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return widget.entries.where((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return entryDate == dateKey;
    }).toList();
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

  Color _getDominantMoodColor(List<JournalEntry> entries) {
    if (entries.isEmpty) return Colors.grey;

    // Count moods
    Map<String?, int> moodCounts = {};
    for (var entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    // Get most frequent mood
    String? dominantMood;
    int maxCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMood = mood;
      }
    });

    return _getMoodColor(dominantMood);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: _previousMonth,
                  color: Colors.grey.shade700,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: _nextMonth,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildCalendarGrid(),
          ),

          // Today button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToToday,
                    icon: Icon(Icons.today_rounded, size: 18, color: Colors.blue.shade600),
                    label: Text(
                      'Today',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.blue.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedDate = null);
                      widget.onDateSelected?.call(null);
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    // Empty cells before first day
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final entries = _getEntriesForDate(date);
      final hasEntries = entries.isNotEmpty;
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;

      dayWidgets.add(_buildDayCell(date, hasEntries, isSelected, isToday, entries));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(
    DateTime date,
    bool hasEntries,
    bool isSelected,
    bool isToday,
    List<JournalEntry> entries,
  ) {
    Color? backgroundColor;
    Color? borderColor;
    Color textColor = Colors.grey.shade900;

    if (isSelected) {
      backgroundColor = Colors.blue.shade600;
      textColor = Colors.white;
    } else if (isToday) {
      borderColor = Colors.blue.shade600;
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedDate?.year == date.year &&
              _selectedDate?.month == date.month &&
              _selectedDate?.day == date.day) {
            _selectedDate = null;
            widget.onDateSelected?.call(null);
          } else {
            _selectedDate = date;
            widget.onDateSelected?.call(date);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            // Mood indicators
            if (hasEntries)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: entries.take(3).map((entry) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : _getMoodColor(entry.mood),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
