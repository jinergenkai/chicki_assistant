// Dart
import 'package:chicki_buddy/core/logger.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

class AssistantSettingsScreen extends StatefulWidget {
  const AssistantSettingsScreen({super.key});

  @override
  State<AssistantSettingsScreen> createState() => _AssistantSettingsScreenState();
}

class _AssistantSettingsScreenState extends State<AssistantSettingsScreen> {
  bool isOnline = true;
  String apiKey = '';
  String selectedModel = 'gpt-oss:20b';
  String systemContext = '';
  final List<String> models = [
    'gpt-oss:20b',
    'gpt-3.5-turbo',
    'gpt-4',
    'llama-2',
    'custom'
  ];
  bool showMenu = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.moonColors?.gohan,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Assistant Settings', style: TextStyle(color: context.moonColors?.bulma)),
            const SizedBox(width: 8),
            MoonTag(
              label: Text(isOnline ? 'Online' : 'Offline'),
              backgroundColor: isOnline ? context.moonColors?.krillin : context.moonColors?.chichi,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
        backgroundColor: context.moonColors?.goku,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: context.moonColors?.goku,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Chat', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.moonColors?.bulma,
                      fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 16),
                    Text('API Key', style: Theme.of(context).textTheme.bodyMedium),
                    MoonFormTextInput(
                      controller: TextEditingController(text: apiKey),
                      onChanged: (val) => setState(() => apiKey = val),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 16),
                    Text('Model', style: Theme.of(context).textTheme.bodyMedium),
                    MoonDropdown(
                      show: showMenu,
                      constrainWidthToChild: true,
                      onTapOutside: () => setState(() {}),
                      content: Column(
                        children: models.map((m) => MoonMenuItem(
                          onTap: () => setState(() {
                            selectedModel = m;
                          logger.info('Toggling dropdown menu');

                            showMenu = false;
                            // Keep dropdown open after selection
                          }),
                          label: Text(m),
                        )).toList(),
                      ),
                      child: MoonTextInput(
                        width: 250,
                        readOnly: true,
                        canRequestFocus: false,
                        mouseCursor: MouseCursor.defer,
                        hintText: selectedModel,
                        onTap: () => setState(() {
                          logger.info('Toggling dropdown menu');
                          showMenu = !showMenu;
                        }),
                        trailing: const Center(
                          child: AnimatedRotation(
                            duration: Duration(milliseconds: 200),
                            turns: 0,
                            child: Icon(MoonIcons.controls_chevron_down_small_16_light),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('System Context', style: Theme.of(context).textTheme.bodyMedium),
                    MoonFormTextInput(
                      controller: TextEditingController(text: systemContext),
                      onChanged: (val) => setState(() => systemContext = val),
                      borderRadius: BorderRadius.circular(12),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Add more settings here...
                    Text('More settings coming soon...', style: TextStyle(color: context.moonColors?.trunks)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: context.moonColors?.goku,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Intent', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.moonColors?.bulma,
                      fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 16),
                    Text('Quick Intent settings coming soon...', style: TextStyle(color: context.moonColors?.trunks)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}