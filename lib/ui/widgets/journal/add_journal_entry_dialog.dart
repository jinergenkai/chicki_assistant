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
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.date;
      _selectedMood = widget.entry!.mood;
      _tags = List<String>.from(widget.entry!.tags ?? []);
      _isFavorite = widget.entry!.isFavorite;
    } else {
      _selectedDate = DateTime.now();
      _selectedMood = 'happy'; // Default mood
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
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    setState(() => _isLoading = true);

    try {
      final journalService = Get.find<JournalService>();

      if (widget.entry != null) {
        widget.entry!.title = _titleController.text.trim();
        widget.entry!.content = _contentController.text.trim();
        widget.entry!.date = _selectedDate;
        widget.entry!.mood = _selectedMood;
        widget.entry!.tags = _tags.isNotEmpty ? _tags : null;
        widget.entry!.isFavorite = _isFavorite;
        widget.entry!.updateWordCount();
        await journalService.updateEntry(widget.entry!);
      } else {
        await journalService.createEntry(
          bookId: widget.bookId,
          date: _selectedDate,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          tags: _tags.isNotEmpty ? _tags : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Journal saved successfully!"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      isEditing ? 'Edit Entry' : 'New Story',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                   padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date & Favorite Row
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _selectDate,
                              icon: Icon(Icons.calendar_today_rounded, size: 18, color: Colors.blue.shade600),
                              label: Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => _isFavorite = !_isFavorite),
                              icon: Icon(
                                _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                color: _isFavorite ? Colors.amber.shade400 : Colors.grey.shade400,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Title
                        TextFormField(
                           controller: _titleController,
                           style: const TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.bold
                           ),
                           decoration: InputDecoration(
                             hintText: "Title your story...",
                             hintStyle: TextStyle(
                               color: Colors.grey.shade400,
                               fontSize: 18,
                               fontWeight: FontWeight.bold
                             ),
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.zero,
                           ),
                           textCapitalization: TextCapitalization.sentences,
                           validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        ),
                        const Divider(height: 32),

                        // Mood Horizontal List
                        Text(
                          "How you felt",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableMoods.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final mood = _availableMoods[index];
                              final isSelected = _selectedMood == mood['name'];
                              
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMood = mood['name']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? (mood['color'] as Color).withOpacity(0.1) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? (mood['color'] as Color) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(mood['emoji'], style: const TextStyle(fontSize: 18)),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          mood['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: mood['color'],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Content
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _contentController,
                            maxLines: 6,
                            style: const TextStyle(height: 1.5),
                            decoration: const InputDecoration(
                              hintText: "Write about your experience...",
                              border: InputBorder.none,
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                         const SizedBox(height: 24),
                        
                        // Tags
                         TextField(
                           controller: _tagController,
                           decoration: InputDecoration(
                             hintText: "Add tags (e.g., #happy)...",
                             prefixIcon: Icon(Icons.tag_rounded, color: Colors.grey.shade400, size: 20),
                             border: OutlineInputBorder(
                               borderRadius: BorderRadius.circular(12),
                               borderSide: BorderSide(color: Colors.grey.shade200),
                             ),
                             contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                           ),
                           onSubmitted: (_) => _addTag(),
                         ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                               backgroundColor: Colors.blue.shade50,
                               side: BorderSide.none,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               onDeleted: () => _removeTag(tag),
                               deleteIconColor: Colors.blue.shade300,
                            )).toList(),
                          ),
                        ],
                         const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                   width: double.infinity,
                   child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           colors: [Colors.blue.shade400, Colors.blue.shade600],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                             color: Colors.blue.withOpacity(0.3),
                             blurRadius: 10,
                             offset: const Offset(0,4)
                          )
                        ]
                      ),
                     child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.transparent,
                           shadowColor: Colors.transparent,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                             isEditing ? "Save Changes" : "Create Entry",
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                     ),
                   ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
