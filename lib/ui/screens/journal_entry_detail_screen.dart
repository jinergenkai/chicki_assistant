import 'package:chicki_buddy/models/journal_entry.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:chicki_buddy/ui/screens/add_journal_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class JournalEntryDetailScreen extends StatefulWidget {
  final JournalEntry entry;
  final VoidCallback? onChanged;

  const JournalEntryDetailScreen({
    super.key,
    required this.entry,
    this.onChanged,
  });

  @override
  State<JournalEntryDetailScreen> createState() =>
      _JournalEntryDetailScreenState();
}

class _JournalEntryDetailScreenState extends State<JournalEntryDetailScreen> {
  late JournalService journalService;
  late JournalEntry entry;

  @override
  void initState() {
    super.initState();
    journalService = Get.find<JournalService>();
    entry = widget.entry;
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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      entry.isFavorite = !entry.isFavorite;
    });
    await journalService.updateEntry(entry);
    widget.onChanged?.call();
  }

  Future<void> _editEntry() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddJournalEntryScreen(
          bookId: entry.bookId,
          entry: entry,
          onSaved: () {
            setState(() {
              // Entry object is already updated
            });
            widget.onChanged?.call();
          },
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      setState(() {
        // Refresh UI
      });
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          'Are you sure you want to delete "${entry.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await journalService.deleteEntry(entry.id!);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onChanged?.call();
      }
    }
  }

  void _showOptionsMenu() {
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
              title: const Text('Edit Entry'),
              onTap: () {
                Navigator.pop(context);
                _editEntry();
              },
            ),
            ListTile(
              leading: Icon(
                entry.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber.shade700,
              ),
              title: Text(
                entry.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Entry'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature - Coming soon!')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteEntry();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _getMoodColor(entry.mood),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    entry.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showOptionsMenu,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                entry.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getMoodColor(entry.mood),
                      _getMoodColor(entry.mood).withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _getMoodEmoji(entry.mood),
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata Card
                  Container(
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
                        _buildMetadataRow(
                          Icons.calendar_today_rounded,
                          'Date',
                          _formatDate(entry.date),
                        ),
                        if (entry.mood != null)
                          _buildMetadataRow(
                            Icons.mood_rounded,
                            'Mood',
                            '${_getMoodEmoji(entry.mood)} ${entry.mood}',
                          ),
                        if (entry.wordCount != null)
                          _buildMetadataRow(
                            Icons.text_fields_rounded,
                            'Word Count',
                            '${entry.wordCount} words',
                          ),
                        _buildMetadataRow(
                          Icons.access_time_rounded,
                          'Created',
                          _formatTime(entry.createdAt),
                        ),
                        if (entry.updatedAt != entry.createdAt)
                          _buildMetadataRow(
                            Icons.update_rounded,
                            'Last Updated',
                            _formatTime(entry.updatedAt),
                          ),
                      ],
                    ),
                  ),

                  // Tags
                  if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
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
                          Row(
                            children: [
                              Icon(Icons.label_rounded,
                                  size: 18, color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              const Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.tags!.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Content Card
                  Container(
                    width: double.infinity,
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
                        Row(
                          children: [
                            Icon(Icons.article_rounded,
                                size: 18, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              'Entry Content',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          entry.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _editEntry,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('EDIT'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                                color: Colors.blue.shade600, width: 1.5),
                            foregroundColor: Colors.blue.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteEntry,
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text('DELETE'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                                color: Colors.red.shade600, width: 1.5),
                            foregroundColor: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
}
