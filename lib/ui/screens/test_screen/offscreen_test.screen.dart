import 'package:chicki_buddy/services/test_data_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';

class OffscreenTestScreen extends StatelessWidget {
  const OffscreenTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final testService = Get.find<TestDataService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offscreen Data Access Test'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Status Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Test Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Text(
                      'Service Status: ${testService.isListening.value ? "🟢 LISTENING" : "🔴 STOPPED"}',
                      style: const TextStyle(fontSize: 16),
                    )),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      'Total Requests: ${testService.requestCount.value}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      'Last Request: ${_formatTime(testService.lastRequestTime.value)}',
                      style: const TextStyle(fontSize: 14),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Test Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Start foreground service\n'
                      '2. Minimize the app (go to home screen)\n'
                      '3. Wait 30 seconds\n'
                      '4. Return to app and check counter\n'
                      '5. Counter should show ~6 requests',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: MoonFilledButton(
                    buttonSize: MoonButtonSize.lg,
                    label: const Text('Trigger Test'),
                    onTap: () => testService.triggerTestFromUI(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MoonOutlinedButton(
                    buttonSize: MoonButtonSize.lg,
                    label: const Text('Reset'),
                    onTap: () => testService.reset(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Responses
            Text(
              '📝 Recent Responses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Obx(() {
                  final responses = testService.responses;
                  if (responses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No responses yet...\nStart the foreground service to begin testing',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: responses.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          responses[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Expected Results
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Success Criteria:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Counter increments every 5 seconds\n'
                    '• Continues when app is offscreen\n'
                    '• No gaps in timestamps\n'
                    '• Response time < 200ms',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}