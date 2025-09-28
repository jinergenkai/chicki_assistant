import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:chicki_buddy/ui/widgets/vocabulary/add_vocabulary_button.dart';
import 'package:flutter/material.dart';
import 'package:vertical_card_pager/vertical_card_pager.dart';

class FlashCardScreen extends StatefulWidget {
  const FlashCardScreen({super.key});

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  final VocabularyService service = VocabularyService();
  List<Vocabulary> vocabList = [];

  @override
  void initState() {
    super.initState();
    service.init().then((_) {
      setState(() {
        vocabList = service.getAll();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (vocabList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flash Cards')),
        body: const Center(child: CircularProgressIndicator()),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
        floatingActionButton: AddVocabularyButton(
          service: service,
          onAdded: () {
            setState(() {
              vocabList = service.getAll();
            });
          },
        ),
      );
    }

    // Tạo list widget cho card
    final List<Widget> cards = vocabList
        .map((v) => Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4))],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    v.word,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (v.pronunciation != null)
                    Text(
                      v.pronunciation!,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                  if (v.meaning != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        v.meaning!,
                        style: const TextStyle(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ))
        .toList();

    // Tạo list title cho card index
    final List<String> titles = List.generate(vocabList.length, (index) => '');

    return Scaffold(
      appBar: AppBar(title: const Text('Flash Cards')),
      body: Center(
        child: VerticalCardPager(
          titles: titles,
          images: cards,
          textStyle: const TextStyle(
            color: Colors.transparent,
          ),
          initialPage: 0,
          onPageChanged: (page) {},
          onSelectedItem: (index) {},
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: AddVocabularyButton(
        service: service,
        onAdded: () {
          setState(() {
            vocabList = service.getAll();
          });
        },
      ),
    );
  }
}
