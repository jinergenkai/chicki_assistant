import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddVocabularyDialog extends StatefulWidget {
  final String bookId;
  final VoidCallback? onAdded;

  const AddVocabularyDialog({
    super.key,
    required this.bookId,
    this.onAdded,
  });

  @override
  State<AddVocabularyDialog> createState() => _AddVocabularyDialogState();
}

class _AddVocabularyDialogState extends State<AddVocabularyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _exampleController = TextEditingController();
  final _exampleTranslationController = TextEditingController();
  final _topicController = TextEditingController();

  int _difficulty = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    _exampleTranslationController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vocabService = Get.find<VocabularyService>();

      await vocabService.addVocabToBook(
        word: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        bookId: widget.bookId,
        topic: _topicController.text.trim().isEmpty ? null : _topicController.text.trim(),
        pronunciation: _pronunciationController.text.trim().isEmpty
            ? null
            : _pronunciationController.text.trim(),
        exampleSentence: _exampleController.text.trim().isEmpty
            ? null
            : _exampleController.text.trim(),
        exampleTranslation: _exampleTranslationController.text.trim().isEmpty
            ? null
            : _exampleTranslationController.text.trim(),
        difficulty: _difficulty,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Added "${_wordController.text.trim()}"'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Vocabulary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Word (required)
                TextFormField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: 'Word *',
                    hintText: 'e.g., ubiquitous',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.spellcheck),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Word is required';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Meaning (required)
                TextFormField(
                  controller: _meaningController,
                  decoration: const InputDecoration(
                    labelText: 'Meaning (Vietnamese) *',
                    hintText: 'e.g., có mặt khắp nơi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Meaning is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Pronunciation (optional)
                TextFormField(
                  controller: _pronunciationController,
                  decoration: const InputDecoration(
                    labelText: 'Pronunciation',
                    hintText: 'e.g., /juːˈbɪkwɪtəs/',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.record_voice_over),
                  ),
                ),
                const SizedBox(height: 16),

                // Example sentence (optional)
                TextFormField(
                  controller: _exampleController,
                  decoration: const InputDecoration(
                    labelText: 'Example Sentence',
                    hintText: 'e.g., Smartphones are ubiquitous...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_quote),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Example translation (optional)
                TextFormField(
                  controller: _exampleTranslationController,
                  decoration: const InputDecoration(
                    labelText: 'Example Translation',
                    hintText: 'Translation of example sentence',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Topic (optional)
                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    hintText: 'e.g., Technology, Business',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),

                // Difficulty slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Difficulty:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < _difficulty ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ],
                    ),
                    Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _difficulty.toString(),
                      onChanged: (value) {
                        setState(() => _difficulty = value.toInt());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
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
                          : const Icon(Icons.add),
                      label: Text(_isLoading ? 'Adding...' : 'Add Vocabulary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
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
