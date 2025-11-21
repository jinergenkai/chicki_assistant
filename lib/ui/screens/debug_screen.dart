import 'package:chicki_buddy/ui/screens/books_screen.dart';
import 'package:chicki_buddy/ui/screens/test_screen/workflow_graph.screen.dart';
import 'package:chicki_buddy/ui/widgets/moon_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';

import 'test_screen/model_test.screen.dart';
import 'test_screen/sherpa_tts_test_screen.dart';
import 'test_screen/test_buddy.screen.dart';
import 'test_screen/chicky_mascot.screen.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  final List<_DebugItem> items = const [
    _DebugItem(
      title: 'Model Test',
      screen: ModelTestScreen(),
    ),
    _DebugItem(
      title: 'Sherpa TTS Test',
      screen: SherpaTtsTestScreen(),
    ),
    _DebugItem(
      title: 'Test Buddy',
      screen: TestBuddyScreen(),
    ),
    _DebugItem(
      title: 'Chicky Mascot',
      screen: ChickyMascotScreen(),
    ),
    _DebugItem(
      title: 'Workflow',
      screen: WorkflowGraphView(),
    ),
        _DebugItem(
      title: 'Book screen',
      screen: BooksScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MoonFilledButton(
          label: const Text('back to user screen'),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = items[idx];
              return MoonFilledButton(
                label: Text(item.title),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => _DebugScreenWrapper(child: item.screen),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DebugItem {
  final String title;
  final Widget screen;
  const _DebugItem({required this.title, required this.screen});
}

class _DebugScreenWrapper extends StatelessWidget {
  final Widget child;
  const _DebugScreenWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: MoonIconButton(
          icon: Icons.close,
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text('Debug'),
      ),
      body: child,
    );
  }
}
