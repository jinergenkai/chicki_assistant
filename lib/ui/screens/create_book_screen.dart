import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:chicki_buddy/models/book.dart';
import 'package:chicki_buddy/services/book_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'dart:math';

class CreateBookScreen extends StatefulWidget {
  const CreateBookScreen({super.key});

  @override
  State<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends State<CreateBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  BookType _selectedType = BookType.flashBook;
  String _selectedCoverId = '';
  List<String> _coverOptions = [];

  void _generateCoverOptions() {
    // Generate 6 random seeds/ids for cover options
    _coverOptions = List.generate(6, (index) => (DateTime.now().millisecondsSinceEpoch + Random().nextInt(10000)).toString());
    _selectedCoverId = _coverOptions.first;
  }


  // Predefined Categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Language', 'icon': LucideIcons.languages},
    {'name': 'Science', 'icon': LucideIcons.microscope},
    {'name': 'History', 'icon': LucideIcons.hourglass},
    {'name': 'Art', 'icon': LucideIcons.palette},
    {'name': 'Travel', 'icon': LucideIcons.plane},
    {'name': 'Daily', 'icon': LucideIcons.sun},
    {'name': 'Work', 'icon': LucideIcons.briefcase},
    {'name': 'Other', 'icon': LucideIcons.moreHorizontal},
  ];

  @override
  void initState() {
    super.initState();
    _generateCoverOptions();
    // Pre-fill author with current user name
    try {
      final appConfig = Get.find<AppConfigController>();
      if (appConfig.userName.value.isNotEmpty) {
        _authorController.text = appConfig.userName.value;
      }
    } catch (_) {
      // Config might not be ready, ignore
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    
    // Validate Current Step
    if (_currentStep == 1) { // Title & Desc
      if (_titleController.text.trim().isEmpty) {
        Get.snackbar("Missing Title", "Please give your book a title.", 
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
        return;
      }
      if (_descriptionController.text.trim().isEmpty) {
        Get.snackbar("Missing Description", "Please write a short description.", 
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
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
      _createBook();
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

  Future<void> _createBook() async {
    setState(() => _isLoading = true);

    try {
      final bookService = Get.find<BookService>();

      final book = await bookService.createNewBook(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      );

      // Set book type and cover
      book.coverId = _selectedCoverId;
      book.type = _selectedType;
      await bookService.updateBook(book);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to signal refresh
        Get.snackbar("Success", "Book created successfully!", 
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.green.shade600, colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar("Error", e.toString(), 
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red.shade600, colorText: Colors.white, margin: const EdgeInsets.all(16), borderRadius: 16);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Book Type';
      case 1: return 'Basic Info';
      case 2: return 'Details';
      case 3: return 'Cover Color';
      default: return 'New Book';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _getStepTitle(),
            key: ValueKey(_currentStep),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
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
                   _buildStep1(), // Type
                   _buildStep2(), // Info
                   _buildStep3(), // Details
                   _buildStep4(), // Color
                ],
              ),
            ),
          ),
        ],
      ),
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
                                  _currentStep < 3 ? 'Continue' : 'Create Book',
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

  // STEP 1: TYPE SELECTION
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBigHeader(LucideIcons.library, Colors.blue.shade600, "What type of book?", "Choose the format for your content."),
          
          _buildTypeCard(
            type: BookType.flashBook,
            title: 'FlashCard',
            desc: 'Learn vocabulary efficiently with flashcards.',
            icon: LucideIcons.graduationCap,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildTypeCard(
            type: BookType.journal,
            title: 'Journal',
            desc: 'Write daily entries, thoughts, and memories.',
            icon: LucideIcons.bookOpen,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildTypeCard(
            type: BookType.story,
            title: 'Story Book',
            desc: 'Read and collect interesting stories.',
            icon: LucideIcons.scroll,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({required BookType type, required String title, required String desc, required IconData icon, required Color color}) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
             color: isSelected ? color : Colors.grey.shade200,
             width: isSelected ? 2 : 1
          ),
          boxShadow: [
             BoxShadow(
                color: isSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)
             )
          ]
        ),
        child: Row(
          children: [
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade50,
                 borderRadius: BorderRadius.circular(12)
               ),
               child: Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? color.withOpacity(0.8) : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  // STEP 2: BASIC INFO
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBigHeader(LucideIcons.type, Colors.indigo.shade600, "Book Information", "Give your book a name and purpose."),

          // Title
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.grey.shade200),
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]
             ),
             child: TextFormField(
               controller: _titleController,
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
               decoration: InputDecoration(
                 labelText: 'Book Title',
                 prefixIcon: Icon(LucideIcons.heading, color: Colors.indigo.shade300),
                 border: InputBorder.none,
                 contentPadding: const EdgeInsets.all(16),
                 floatingLabelBehavior: FloatingLabelBehavior.auto,
               ),
               textCapitalization: TextCapitalization.words,
             ),
          ),
          const SizedBox(height: 20),

          // Description
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.grey.shade200),
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]
             ),
             child: TextFormField(
               controller: _descriptionController,
               maxLines: 4,
               style: const TextStyle(fontSize: 16),
               decoration: InputDecoration(
                 labelText: 'Description',
                 alignLabelWithHint: true,
                 prefixIcon: Padding(
                   padding: const EdgeInsets.only(bottom: 60), // Align icon top
                   child: Icon(LucideIcons.alignLeft, color: Colors.indigo.shade300),
                 ),
                 hintText: 'What is this book about?',
                 border: InputBorder.none,
                 contentPadding: const EdgeInsets.all(16),
               ),
             ),
          ),
        ],
      ),
    );
  }

  // STEP 3: DETAILS
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBigHeader(LucideIcons.tag, Colors.teal.shade600, "Final Details", "Who is the author? What category?"),

           // Author
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.grey.shade200),
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]
             ),
             child: TextFormField(
               controller: _authorController,
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
               decoration: InputDecoration(
                 labelText: 'Author',
                 prefixIcon: Icon(LucideIcons.user, color: Colors.teal.shade300),
                 border: InputBorder.none,
                 contentPadding: const EdgeInsets.all(16),
               ),
             ),
          ),
          const SizedBox(height: 24),

          // Category Chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600))
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _categories.map((cat) {
              final isSelected = _categoryController.text == cat['name'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'], size: 14, color: isSelected ? Colors.white : Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(cat['name']),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _categoryController.text = selected ? cat['name'] : '';
                  });
                },
                selectedColor: Colors.teal.shade500,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200)),
              );
            }).toList(),
          ),
          
          if (_categoryController.text.isNotEmpty && !_categories.any((c) => c['name'] == _categoryController.text))
             // If manual text entry (though we only used chips here, easy to extend if needed)
             Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Chip(label: Text(_categoryController.text), backgroundColor: Colors.teal.shade100),
             )

        ],
      ),
    );
  }


  // STEP 4: COVER SELECTION
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildBigHeader(LucideIcons.palette, Colors.pink.shade600, "Pick a Cover", "Choose a style that fits your book."),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: _coverOptions.length,
            itemBuilder: (context, index) {
              final id = _coverOptions[index];
              final isSelected = _selectedCoverId == id;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedCoverId = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? Border.all(color: Colors.pink.shade600, width: 3) : Border.all(color: Colors.transparent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RandomGradient(
                           id,
                           seed: "bookCardGradient",
                           child: Container(),
                        ),
                        if (isSelected)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check, color: Colors.pink.shade600, size: 20),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _generateCoverOptions();
              });
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text("Generate New Colors"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          )
        ],
      ),
    );
  }
}
