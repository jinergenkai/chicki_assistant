import 'dart:async';

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:chicki_buddy/ui/screens/flash_card.screen.dart';
import 'package:chicki_buddy/ui/screens/flash_card_screen2.dart';
import 'package:chicki_buddy/utils/gradient.dart';
import 'package:chicki_buddy/voice/models/voice_action_event.dart';
import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/topic.dart';

class TopicScreen extends StatefulWidget {
  final Book book;
  const TopicScreen({super.key, required this.book});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  StreamSubscription? _voiceActionSub;

  void openTopic(String topicId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FlashCardScreen2(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _voiceActionSub = eventBus.stream.where((e) => e.type == AppEventType.voiceAction).listen((event) {
      final action = event.payload;
      if (action is VoiceActionEvent && action.action == 'selectTopic' && action.data['topicId'] != null) {
        openTopic(action.data['topicId']);
      }
    });
  }

  @override
  void dispose() {
    _voiceActionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
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
                          overflow: TextOverflow.ellipsis,
                          // maxLines: 2,
                          softWrap: true,
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
                            subtitle: Text('${topic.vocabList.length} vocabularies', style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                            onTap: () => openTopic(topic.id),
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
