import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:flutter/material.dart';

class AddVocabularyButton extends StatelessWidget {
  final VocabularyService service;
  final VoidCallback? onAdded; // callback khi thêm xong để refresh UI

  const AddVocabularyButton({
    super.key,
    required this.service,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        _showAddDialog(context);
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final wordController = TextEditingController();
    final meaningController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vocabulary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordController,
              decoration: const InputDecoration(labelText: 'Word'),
            ),
            TextField(
              controller: meaningController,
              decoration: const InputDecoration(labelText: 'Meaning'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final word = wordController.text.trim();
              final meaning = meaningController.text.trim();
              if (word.isEmpty) return;

              final vocab = Vocabulary(
                word: word,
                originLanguage: 'en',
                targetLanguage: 'vi',
                meaning: meaning.isEmpty ? null : meaning,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await service.upsertVocabulary(vocab);
              Navigator.of(context).pop();
              if (onAdded != null) onAdded!();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
