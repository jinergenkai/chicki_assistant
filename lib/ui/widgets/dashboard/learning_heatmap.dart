import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:intl/intl.dart';

class LearningHeatmap extends StatefulWidget {
  const LearningHeatmap({super.key});

  @override
  State<LearningHeatmap> createState() => _LearningHeatmapState();
}

class _LearningHeatmapState extends State<LearningHeatmap> {
  late final AppConfigController appConfig;

  @override
  void initState() {
    super.initState();
    appConfig = Get.find<AppConfigController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dailyVocabLearned = appConfig.dailyVocabLearned.value;
      
      // Get last 30 days
      final today = DateTime.now();
      final last30Days = List.generate(30, (index) {
        return today.subtract(Duration(days: 29 - index));
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Heatmap grid
          SizedBox(
            height: 120,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 28, // 4 weeks
              itemBuilder: (context, index) {
                if (index >= last30Days.length) return const SizedBox.shrink();
                
                final date = last30Days[index];
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final vocabCount = dailyVocabLearned[dateKey] ?? 0;

                return _HeatmapCell(
                  date: date,
                  count: vocabCount,
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Less',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 4),
              _LegendBox(color: Colors.grey.shade200),
              const SizedBox(width: 2),
              _LegendBox(color: Colors.green.shade200),
              const SizedBox(width: 2),
              _LegendBox(color: Colors.green.shade400),
              const SizedBox(width: 2),
              _LegendBox(color: Colors.green.shade600),
              const SizedBox(width: 4),
              const Text(
                'More',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime date;
  final int count;

  const _HeatmapCell({
    required this.date,
    required this.count,
  });

  Color _getColor() {
    if (count == 0) return Colors.grey.shade200;
    if (count <= 5) return Colors.green.shade200;
    if (count <= 10) return Colors.green.shade400;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${DateFormat('MMM d').format(date)}: $count words',
      child: Container(
        decoration: BoxDecoration(
          color: _getColor(),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;

  const _LegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}