import 'package:chicki_buddy/models/journal_entry.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddJournalEntryDialog extends StatefulWidget {
  final String bookId;
  final JournalEntry? entry; // If editing existing entry
  final VoidCallback? onSaved;

  const AddJournalEntryDialog({
    super.key,
    required this.bookId,
    this.entry,
    this.onSaved,
  });

  @override
  State<AddJournalEntryDialog> createState() => _AddJournalEntryDialogState();
}

class _AddJournalEntryDialogState extends State<AddJournalEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  late DateTime _selectedDate;
  String? _selectedMood;
  List<String> _tags = [];
  bool _isFavorite = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableMoods = [
    {'name': 'happy', 'emoji': '😊', 'color': Colors.green},
    {'name': 'sad', 'emoji': '😢', 'color': Colors.blue},
    {'name': 'excited', 'emoji': '🎉', 'color': Colors.orange},
    {'name': 'anxious', 'emoji': '😰', 'color': Colors.orange},
    {'name': 'calm', 'emoji': '😌', 'color': Colors.teal},
    {'name': 'grateful', 'emoji': '🙏', 'color': Colors.purple},
    {'name': 'hopeful', 'emoji': '🌟', 'color': Colors.amber},
    {'name': 'accomplished', 'emoji': '🎯', 'color': Colors.indigo},
    {'name': 'frustrated', 'emoji': '😤', 'color': Colors.red},
    {'name': 'neutral', 'emoji': '😐', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      // Editing existing entry
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.date;
      _selectedMood = widget.entry!.mood;
      _tags = List<String>.from(widget.entry!.tags ?? []);
      _isFavorite = widget.entry!.isFavorite;
    } else {
      // Creating new entry
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final journalService = Get.find<JournalService>();

      if (widget.entry != null) {
        // Update existing entry
        widget.entry!.title = _titleController.text.trim();
        widget.entry!.content = _contentController.text.trim();
        widget.entry!.date = _selectedDate;
        widget.entry!.mood = _selectedMood;
        widget.entry!.tags = _tags.isNotEmpty ? _tags : null;
        widget.entry!.isFavorite = _isFavorite;
        widget.entry!.updateWordCount();
        await journalService.updateEntry(widget.entry!);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Entry updated successfully!')),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        // Create new entry
        await journalService.createEntry(
          bookId: widget.bookId,
          date: _selectedDate,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          tags: _tags.isNotEmpty ? _tags : null,
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Entry "${_titleController.text.trim()}" created!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }

      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_circle_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Picker
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: Colors.blue.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEEE, MMMM dd, yyyy')
                                          .format(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g., A Great Day',
                          prefixIcon: const Icon(Icons.title_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        autofocus: !isEditing,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Content Field
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content *',
                          hintText: 'Write about your day...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.notes_rounded),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please write something';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 20),

                      // Mood Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mood_rounded,
                                  size: 20, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'How are you feeling?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableMoods.map((mood) {
                              final isSelected = _selectedMood == mood['name'];
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(mood['emoji'] as String,
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text(
                                      mood['name'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedMood =
                                        selected ? mood['name'] as String : null;
                                  });
                                },
                                selectedColor:
                                    (mood['color'] as Color).withOpacity(0.2),
                                backgroundColor: Colors.grey.shade100,
                                side: BorderSide(
                                  color: isSelected
                                      ? mood['color'] as Color
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tags Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.label_rounded,
                                  size: 20, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a tag...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addTag(),
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addTag,
                                icon: Icon(Icons.add_circle,
                                    color: Colors.blue.shade600),
                                tooltip: 'Add tag',
                              ),
                            ],
                          ),
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _tags.map((tag) {
                                return Chip(
                                  label: Text('#$tag'),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: Colors.blue.shade50,
                                  side: BorderSide(
                                      color: Colors.blue.shade200),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Favorite Toggle
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Mark as favorite',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Switch(
                              value: _isFavorite,
                              onChanged: (value) {
                                setState(() => _isFavorite = value);
                              },
                              activeColor: Colors.amber.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                    label: Text(_isLoading
                        ? 'Saving...'
                        : isEditing
                            ? 'Save Changes'
                            : 'Create Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
