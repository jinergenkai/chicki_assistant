import 'dart:async';

import 'package:chicki_buddy/voice/dispatcher/voice_intent_dispatcher.dart';
import 'package:chicki_buddy/voice/models/voice_state_context.dart';
import 'package:flutter/material.dart';
import '../../voice/simulator/intent_simulator.dart';
import '../../core/app_event_bus.dart';
import '../../voice/models/voice_action_event.dart';

class IntentTestScreen extends StatefulWidget {
  const IntentTestScreen({super.key});

  @override
  State<IntentTestScreen> createState() => _IntentTestScreenState();
}

class _IntentTestScreenState extends State<IntentTestScreen> {
  final IntentSimulator _simulator = IntentSimulator();
  final List<String> _logs = [];
  final VoiceStateContext _graphState = VoiceStateContext(currentScreen: 'idle');
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = eventBus.stream
      .where((e) => e.type == AppEventType.voiceAction)
      .listen((event) {
        final action = event.payload as VoiceActionEvent;
        // Update graph state based on action event
        switch (action.action) {
          case 'selectBook':
            _graphState.currentBookId = action.data['bookId'];
            _graphState.currentScreen = 'bookSelected';
            break;
          case 'selectTopic':
            _graphState.currentTopicId = action.data['topicId'];
            _graphState.currentScreen = 'topicSelected';
            break;
          case 'nextVocab':
            _graphState.currentCardIndex = action.data['cardIndex'];
            _graphState.currentScreen = 'vocabCard';
            break;
          case 'readAloud':
            // No state change, just TTS
            break;
          default:
            break;
        }
        if (mounted) {
          setState(() {
            _logs.add('Action: ${action.action}, Data: ${action.data}');
          });
        }
      });
  }


  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intent Test Simulator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _simulator.emitSelectBook('English Starter'),
                  child: const Text('Select Book'),
                ),
                ElevatedButton(
                  onPressed: () => _simulator.emitSelectTopic('Animals'),
                  child: const Text('Select Topic'),
                ),
                ElevatedButton(
                  onPressed: () => _simulator.emitNextVocab(),
                  child: const Text('Next Vocab'),
                ),
                ElevatedButton(
                  onPressed: () => _simulator.emitReadAloud(),
                  child: const Text('Read Aloud'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Action Log:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(_logs[index]),
              ),
            ),
            const GraphRunnerWidget(),
          ],
        ),
      ),
    );
  }
}

class GraphRunnerWidget extends StatefulWidget {
  const GraphRunnerWidget({super.key});

  @override
  State<GraphRunnerWidget> createState() => _GraphRunnerWidgetState();
}

class _GraphRunnerWidgetState extends State<GraphRunnerWidget> {
  final VoiceIntentDispatcher _dispatcher = VoiceIntentDispatcher();
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = eventBus.stream
      .where((e) => e.type == AppEventType.voiceAction)
      .listen((event) {
        final action = event.payload as VoiceActionEvent;
        switch (action.action) {
          case 'selectBook':
            _dispatcher.state.currentBookId = action.data['bookId'];
            _dispatcher.state.currentScreen = 'bookSelected';
            break;
          case 'selectTopic':
            _dispatcher.state.currentTopicId = action.data['topicId'];
            _dispatcher.state.currentScreen = 'topicSelected';
            break;
          case 'nextVocab':
            _dispatcher.state.currentCardIndex = action.data['cardIndex'];
            _dispatcher.state.currentScreen = 'vocabCard';
            break;
          case 'readAloud':
            // No state change, just TTS
            break;
          default:
            break;
        }
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Graph Runner State', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Screen: ${_dispatcher.state.currentScreen}'),
            Text('Book: ${_dispatcher.state.currentBookId ?? "-"}'),
            Text('Topic: ${_dispatcher.state.currentTopicId ?? "-"}'),
            Text('Card Index: ${_dispatcher.state.currentCardIndex ?? "-"}'),
            Text('Mode: ${_dispatcher.state.mode ?? "-"}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _dispatcher.reset();
                });
              },
              child: const Text('Reset Graph State'),
            ),
          ],
        ),
      ),
    );
  }
}