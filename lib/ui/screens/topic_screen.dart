import 'package:chicki_buddy/utils/gradient.dart';
import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/topic.dart';

class TopicScreen extends StatelessWidget {
  final Book book;
  const TopicScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'book_${book.id}',
                child: Material(
                  color: Colors.transparent,
                  child: RandomGradient(
                    book.id,
                    seed: "bookCardGradient",
                    child: Container(
                      margin: const EdgeInsets.only(top: 48, left: 24, right: 24),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 8),
                          Text(book.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 56,
                left: 32,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                itemCount: book.topics.length,
                itemBuilder: (context, index) {
                  final topic = book.topics[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: 90,
                            child: Stack(
                              children: [
                                RandomGradient(
                                  topic.id,
                                  child: Container(
                                    height: 90,
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: ListTile(
                            title: Text(topic.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                )),
                            subtitle: Text('${topic.vocabList.length} vocabularies',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                            onTap: () {
                              // TODO: Navigate to vocabulary screen with animation
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}