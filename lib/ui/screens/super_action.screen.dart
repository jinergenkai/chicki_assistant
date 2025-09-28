import 'package:flutter/material.dart';

class SuperControlScreen extends StatelessWidget {
  const SuperControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        "title": "Add Vocabulary",
        "icon": Icons.book,
        "color": Colors.blue,
        "callback": () async {
          print("Create Vocabulary running...");
          // gọi service add vocab
        },
      },
      {
        "title": "Add Voice Note",
        "icon": Icons.mic,
        "color": Colors.green,
        "callback": () async {
          print("Add Voice Note running...");
          // gọi service add voice note
        },
      },
      {
        "title": "Run Device Command",
        "icon": Icons.settings_remote,
        "color": Colors.orange,
        "callback": () async {
          print("Device command running...");
          // gọi command control thiết bị
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Super Control Test')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => (action["callback"] as Future<void> Function())(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (action["color"] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (action["color"] as Color).withOpacity(0.2),
                      child: Icon(action["icon"] as IconData, color: action["color"] as Color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        action["title"] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
