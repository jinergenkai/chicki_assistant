import 'dart:io';
import 'package:chicki_buddy/models/journal_entry.dart';
import 'package:chicki_buddy/services/journal_service.dart';
import 'package:chicki_buddy/services/attachment_service.dart';
import 'package:chicki_buddy/ui/widgets/journal/voice_recorder_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final String bookId;
  final JournalEntry? entry; // If editing existing entry
  final VoidCallback? onSaved;

  const AddJournalEntryScreen({
    super.key,
    required this.bookId,
    this.entry,
    this.onSaved,
  });

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  final PageController _pageController = PageController();
  final AttachmentService _attachmentService = AttachmentService();
  int _currentStep = 0;

  late DateTime _selectedDate;
  String? _selectedMood;
  List<String> _tags = [];
  List<String> _attachments = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableMoods = [
    {'name': 'Happy', 'emoji': '😊', 'color': Colors.green},
    {'name': 'Sad', 'emoji': '😢', 'color': Colors.blue},
    {'name': 'Excited', 'emoji': '🎉', 'color': Colors.orange},
    {'name': 'Anxious', 'emoji': '😰', 'color': Colors.orange},
    {'name': 'Calm', 'emoji': '😌', 'color': Colors.teal},
    {'name': 'Grateful', 'emoji': '🙏', 'color': Colors.purple},
    {'name': 'Hopeful', 'emoji': '🌟', 'color': Colors.amber},
    {'name': 'Accomplished', 'emoji': '🎯', 'color': Colors.indigo},
    {'name': 'Frustrated', 'emoji': '😤', 'color': Colors.red},
    {'name': 'Neutral', 'emoji': '😐', 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _defaultTags = [
    {'name': 'Work', 'icon': Icons.work_rounded, 'color': Colors.blue},
    {'name': 'Family', 'icon': Icons.family_restroom_rounded, 'color': Colors.pink},
    {'name': 'Friends', 'icon': Icons.groups_rounded, 'color': Colors.orange},
    {'name': 'School', 'icon': Icons.school_rounded, 'color': Colors.red},
    {'name': 'Travel', 'icon': Icons.flight_takeoff_rounded, 'color': Colors.purple},
    {'name': 'Food', 'icon': Icons.restaurant_rounded, 'color': Colors.green},
    {'name': 'Exercise', 'icon': Icons.fitness_center_rounded, 'color': Colors.teal},
    {'name': 'Hobbies', 'icon': Icons.palette_rounded, 'color': Colors.deepOrange},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Colors.indigo},
    {'name': 'Music', 'icon': Icons.music_note_rounded, 'color': Colors.deepPurple},
    {'name': 'Weather', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber},
    {'name': 'Relaxing', 'icon': Icons.spa_rounded, 'color': Colors.lightGreen},
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
      _attachments = List<String>.from(widget.entry!.attachments ?? []);
    } else {
      _selectedDate = DateTime.now();
      _selectedMood = 'Happy';
    }
  }

  Future<void> _addPhoto() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
         decoration: const BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.vertical(top: Radius.circular(24))
         ),
         padding: const EdgeInsets.all(24),
         child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                 child: Icon(Icons.camera_alt_rounded, color: Colors.blue.shade600),
              ),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final path = await _attachmentService.takePhoto(
                  widget.bookId,
                  widget.entry?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                );
                Navigator.pop(context, path);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                 child: Icon(Icons.photo_library_rounded, color: Colors.purple.shade600),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final path = await _attachmentService.pickImageFromGallery(
                  widget.bookId,
                  widget.entry?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                );
                Navigator.pop(context, path);
              },
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _attachments.add(result));
    }
  }

  Future<void> _addVoiceNote() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2), // Better layering
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text(
                'Record Voice Note',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: VoiceRecorderWidget(
                  onRecordingComplete: (audioPath) async {
                    final savedPath = await _attachmentService.saveAudioRecording(
                      audioPath,
                      widget.bookId,
                      widget.entry?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    );
                    if (savedPath != null) {
                      setState(() => _attachments.add(savedPath));
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeAttachment(String path) {
    setState(() => _attachments.remove(path));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _pageController.dispose();
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

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    // Validate Current Step
    if (_currentStep == 0) {
      // Mood Step - Optional? User flow doesn't strictly enforce, but good to check
    } else if (_currentStep == 2) { // Date & Title (was Step 1)
      if (_titleController.text.trim().isEmpty) {
        Get.snackbar("Missing Title", "Please give your entry a title to continue.", snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
        return;
      }
    } else if (_currentStep == 3) { // Story (was Step 2)
       if (_contentController.text.trim().isEmpty) {
        Get.snackbar("Empty Content", "Please write something before submitting.", snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _handleSubmit();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final journalService = Get.find<JournalService>();

      if (widget.entry != null) {
        widget.entry!.title = _titleController.text.trim();
        widget.entry!.content = _contentController.text.trim();
        widget.entry!.date = _selectedDate;
        widget.entry!.mood = _selectedMood;
        widget.entry!.tags = _tags.isNotEmpty ? _tags : null;
        widget.entry!.attachments = _attachments.isNotEmpty ? _attachments : null;
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
          attachments: _attachments.isNotEmpty ? _attachments : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        Get.snackbar("Success", "Journal entry saved!", 
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.green.shade600, colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
      }
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        Get.snackbar("Error", e.toString(), 
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red.shade600, colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isEditing ? 'Edit Story' : _getStepTitle(),
            key: ValueKey(_currentStep),
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20), // Slightly smaller for fit
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Progress Indicator (4 Steps)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(4, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue.shade600 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0,2))] : null
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                   _buildStep1(), // Mood
                   _buildStep2(), // Tags
                   _buildStep3(), // Date & Title
                   _buildStep4(), // Story
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isKeyboardOpen
          ? FloatingActionButton(
              onPressed: _nextStep,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            )
          : null,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton(
                          onPressed: _isLoading ? null : _previousStep,
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _currentStep < 3 ? 'Continue' : 'Finish',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
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

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'How are you?';
      case 1:
        return 'Themes';
      case 2:
        return 'Title & Date';
      case 3:
        return 'Your Story';
      default:
        return 'New Story';
    }
  }

  // Helper for Big Headers
  Widget _buildBigHeader(IconData icon, Color color, String title, String subtitle) {
     return Column(
        children: [
          const SizedBox(height: 12),
          Container(
             width: 72, height: 72,
             decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
             child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 32),
        ],
     );
  }

  // STEP 1: MOOD
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBigHeader(Icons.mood_rounded, Colors.amber.shade600, "How are you feeling?", "Choose a mood that matches your day."),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _availableMoods.length,
            itemBuilder: (context, index) {
              final mood = _availableMoods[index];
              final isSelected = _selectedMood == mood['name'];
              final color = mood['color'] as Color;

              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade100,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood['emoji'],
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mood['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? color : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // STEP 2: TAGS
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
         children: [
            _buildBigHeader(Icons.category_rounded, Colors.indigo.shade600, "What's it about?", "Select themes for your memory."),
            
            GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _defaultTags.length,
            itemBuilder: (context, index) {
              final tag = _defaultTags[index];
              final isSelected = _tags.contains(tag['name']);
              final color = tag['color'] as Color;

              return GestureDetector(
                onTap: () => _toggleTag(tag['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade100,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected 
                      ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                           color: isSelected ? Colors.white : color.withOpacity(0.1),
                           shape: BoxShape.circle
                        ),
                        child: Icon(tag['icon'], color: color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tag['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
         ],
      ),
    );
  }

  // STEP 3: DATE & TITLE
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
           _buildBigHeader(Icons.calendar_month_rounded, Colors.blue.shade600, "When did this happen?", "Give your memory a title and date."),

           // Date Selection Card
           InkWell(
             onTap: _selectDate,
             borderRadius: BorderRadius.circular(20),
             child: Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.grey.shade100),
                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0,5))]
               ),
               child: Row(
                 children: [
                   const Icon(Icons.event_note_rounded, color: Colors.orange, size: 28),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("Date", style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                       Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const Spacer(),
                   const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                 ],
               ),
             ),
           ),
           const SizedBox(height: 24),

           // Title Card
            Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.grey.shade100),
                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0,5))]
               ),
               child: TextFormField(
                 controller: _titleController,
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                 decoration: InputDecoration(
                   prefixIcon: Icon(Icons.title_rounded, color: Colors.purple.shade300),
                   hintText: "Enter a title...",
                   hintStyle: TextStyle(color: Colors.grey.shade400),
                   border: InputBorder.none,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                 ),
                 textCapitalization: TextCapitalization.sentences,
               ),
            ),
        ],
      ),
    );
  }

  // STEP 4: STORY & ATTACHMENTS
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBigHeader(Icons.edit_note_rounded, Colors.purple.shade600, "What's the story?", "Write down your thoughts."),

          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(24),
               border: Border.all(color: Colors.grey.shade100),
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0,5))]
             ),
             child: Column(
               children: [
                 TextFormField(
                   controller: _contentController,
                   maxLines: 8,
                   style: const TextStyle(fontSize: 16, height: 1.5),
                   decoration: InputDecoration(
                     hintText: "Start writing here...",
                     hintStyle: TextStyle(color: Colors.grey.shade400),
                     border: InputBorder.none,
                   ),
                 ),
                 const Divider(height: 32),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     _buildAttachButton(Icons.camera_alt_rounded, "Photo", _addPhoto),
                     _buildAttachButton(Icons.mic_rounded, "Voice", _addVoiceNote),
                   ],
                 )
               ],
             ),
          ),

          if (_attachments.isNotEmpty) ...[
             const SizedBox(height: 24),
             SizedBox(
               height: 100,
               child: ListView.separated(
                 scrollDirection: Axis.horizontal,
                 itemCount: _attachments.length,
                 separatorBuilder: (_,__) => const SizedBox(width: 12),
                 itemBuilder: (context, index) {
                   final path = _attachments[index];
                   final isImage = _attachmentService.getPhotoPaths([path]).isNotEmpty;
                   return Stack(
                     children: [
                       Container(
                         width: 100, height: 100,
                         decoration: BoxDecoration(
                           color: Colors.grey.shade100,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Colors.grey.shade200),
                           image: isImage ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
                         ),
                         child: !isImage ? Icon(Icons.graphic_eq_rounded, color: Colors.grey.shade400) : null,
                       ),
                       Positioned(
                         top: 4, right: 4,
                         child: GestureDetector(
                           onTap: () => _removeAttachment(path),
                           child: CircleAvatar(radius: 10, backgroundColor: Colors.white, child: Icon(Icons.close, size: 12, color: Colors.grey.shade700)),
                         ),
                       )
                     ],
                   );
                 },
               ),
             )
          ]
        ],
      ),
    );
  }

  Widget _buildAttachButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}