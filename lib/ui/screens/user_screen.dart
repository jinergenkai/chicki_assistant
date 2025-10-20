import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/ui/widgets/moon_icon_button.dart';
import 'package:chicki_buddy/ui/widgets/moons_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:moon_design/moon_design.dart';

import 'debug_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Dummy data
    const int streak = 7;
    final List<Map<String, dynamic>> badges = [
      {'label': 'Premium', 'color': Colors.amber[600]},
      {'label': 'Online', 'color': Colors.green[300]},
      {'label': 'Cute', 'color': Colors.pink[200]},
      {'label': 'Streak', 'color': Colors.blue[200]},
    ];
    final List<Map<String, String>> configs = [
      {'Ngôn ngữ': 'Tiếng Việt'},
      {'Màu app': 'Xanh dương'},
    ];

    // Badge widget
    Widget userBadge({required String label, Color? color}) {
      Color bgColor = (color ?? Colors.primaries[label.hashCode % Colors.primaries.length][100])!;
      Color textColor = bgColor.withOpacity(1.0);
      textColor = bgColor.withValues(alpha: 0.8);
      bgColor = bgColor.withValues(alpha: 0.3);
      return MoonTag(
        height: 16,
        label: Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double squareSize = screenWidth * 0.5;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Top: 2 phần trái phải chiếm 50% chiều rộng, chiều cao = 50% width
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left avatar part
            Container(
              width: squareSize,
              height: squareSize,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(0),
                    ),
                    child: Image.asset(
                      'assets/black_overlay.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Icon(
                        LucideIcons.userCircle2,
                        size: squareSize * 0.5,
                        color: const Color.fromARGB(255, 56, 56, 56),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right info part
            SizedBox(
              width: squareSize,
              height: squareSize,
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.circular(32),
              //   boxShadow: const [
              //     BoxShadow(
              //       color: Colors.black12,
              //       blurRadius: 16,
              //       offset: Offset(0, 8),
              //     ),
              //   ],
              // ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MoonIconButton(
                          icon: LucideIcons.settings,
                          onTap: () {},
                        ),
                        MoonIconButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DebugScreen()),
                            );
                          },
                          icon: LucideIcons.bug,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Username + badge
                    const Text(
                      'Manh Hung',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 16,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: badges.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) => userBadge(label: badges[idx]['label'], color: badges[idx]['color']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Dưới: main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: ListView(
              children: [
                // Streak progress
                MoonsCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: streak / 30,
                            minHeight: 12,
                            backgroundColor: Colors.grey[300],
                            color: Colors.orange[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('$streak ngày liên tiếp', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Contact support
                MoonsCard(
                  child: ListTile(
                    leading: const Icon(Icons.support_agent, color: Colors.blue),
                    title: const Text('Liên hệ hỗ trợ'),
                    subtitle: const Text('Nhận trợ giúp từ đội ngũ'),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 8),
                // Request new feature
                MoonsCard(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.amber),
                    title: const Text('Đề xuất tính năng mới'),
                    subtitle: const Text('Gửi ý tưởng cho ứng dụng'),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
