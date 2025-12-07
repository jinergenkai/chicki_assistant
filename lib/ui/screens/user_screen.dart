import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/ui/widgets/moon_icon_button.dart';
import 'package:chicki_buddy/ui/widgets/moons_card.dart';
import 'package:chicki_buddy/ui/widgets/dashboard/learning_heatmap.dart';
import 'package:chicki_buddy/ui/widgets/dashboard/stats_card.dart';
import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:moon_design/moon_design.dart';
import 'package:get/get.dart';

import 'debug_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AppConfigController appConfig;
  final ScrollController _scrollController = ScrollController();
  double _avatarScale = 1.0;
  double _headerOpacity = 1.0;

  // Animation controllers for entrance
  late AnimationController _avatarAnimController;
  late AnimationController _nameAnimController;
  late AnimationController _actionsAnimController;
  late AnimationController _contentAnimController;

  late Animation<double> _avatarScaleAnim;
  late Animation<double> _avatarFadeAnim;
  late Animation<Offset> _nameSlideAnim;
  late Animation<double> _nameFadeAnim;
  late Animation<double> _actionsFadeAnim;
  late Animation<double> _contentFadeAnim;

  @override
  void initState() {
    super.initState();
    appConfig = Get.find<AppConfigController>();

    // Initialize entrance animations
    _avatarAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _nameAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _actionsAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Avatar animations
    _avatarScaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _avatarAnimController, curve: Curves.elasticOut),
    );
    _avatarFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarAnimController, curve: Curves.easeIn),
    );

    // Name animations
    _nameSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _nameAnimController, curve: Curves.easeOut));
    _nameFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_nameAnimController);

    // Actions fade in
    _actionsFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_actionsAnimController);

    // Content fade in
    _contentFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_contentAnimController);

    // Start staggered animations
    Future.delayed(const Duration(milliseconds: 100), () {
      _avatarAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _nameAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _actionsAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _contentAnimController.forward();
    });

    // Listen to scroll for avatar animation
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      setState(() {
        // Scale avatar from 1.0 to 0.6 as we scroll
        _avatarScale = (1.0 - (offset / 200)).clamp(0.6, 1.0);
        // Fade header as we scroll
        _headerOpacity = (1.0 - (offset / 150)).clamp(0.3, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _avatarAnimController.dispose();
    _nameAnimController.dispose();
    _actionsAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern Header with animated avatar
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        children: [
                          // Top row with actions (animated)
                          FadeTransition(
                            opacity: _actionsFadeAnim,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(LucideIcons.settings, size: 20, color: Colors.grey.shade700),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const DebugScreen()),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(LucideIcons.bug, size: 20, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Avatar and name - centered with entrance animations
                          Opacity(
                            opacity: _headerOpacity,
                            child: Column(
                              children: [
                                // Animated Avatar with entrance animation
                                FadeTransition(
                                  opacity: _avatarFadeAnim,
                                  child: ScaleTransition(
                                    scale: _avatarScaleAnim,
                                    child: AnimatedScale(
                                      scale: _avatarScale,
                                      duration: const Duration(milliseconds: 100),
                                      child: Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(32),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 24,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Obx(() {
                                          final avatarId = appConfig.userAvatar.value;
                                          final avatarPath = avatarId.isNotEmpty
                                              ? 'assets/avatar/$avatarId.png'
                                              : 'assets/avatar/dog.png';
                                          
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(32),
                                            child: Image.asset(
                                              avatarPath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                // Fallback to dog avatar if selected avatar not found
                                                return Image.asset(
                                                  'assets/avatar/dog.png',
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Name with slide animation
                                FadeTransition(
                                  opacity: _nameFadeAnim,
                                  child: SlideTransition(
                                    position: _nameSlideAnim,
                                    child: Obx(() {
                                      final userName = appConfig.userName.value;
                                      return Text(
                                        userName.isNotEmpty ? userName : 'User',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main content with modern white container (animated)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentFadeAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Dashboard Stats Section
                  Row(
                    children: [
                      Icon(LucideIcons.barChart, color: Colors.blue.shade600, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  children: [
                    Obx(() => StatsCard(
                      title: 'Streak',
                      value: '${appConfig.currentStreak.value}',
                      icon: LucideIcons.flame,
                      color: Colors.orange,
                      subtitle: 'days in a row',
                    )),
                    Obx(() => StatsCard(
                      title: 'Total Words',
                      value: '${appConfig.totalVocabLearned.value}',
                      icon: LucideIcons.bookOpen,
                      color: Colors.blue,
                      subtitle: 'learned',
                    )),
                    Obx(() => StatsCard(
                      title: 'Reviews',
                      value: '${appConfig.totalReviewCount.value}',
                      icon: LucideIcons.repeat,
                      color: Colors.green,
                      subtitle: 'completed',
                    )),
                    Obx(() => StatsCard(
                      title: 'Level',
                      value: '${appConfig.level.value}',
                      icon: LucideIcons.trophy,
                      color: Colors.amber,
                      subtitle: '${appConfig.totalXP.value} XP',
                    )),
                  ],
                ),

                  const SizedBox(height: 20),

                  // Learning Heatmap
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: LearningHeatmap(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mastery Breakdown
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.pieChart, color: Colors.green.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Mastery Breakdown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _buildMasteryBar(
                          'Mastered',
                          0.6,
                          Colors.green,
                          '60%',
                        ),
                        const SizedBox(height: 12),
                        _buildMasteryBar(
                          'Reviewing',
                          0.25,
                          Colors.blue,
                          '25%',
                        ),
                        const SizedBox(height: 12),
                          _buildMasteryBar(
                            'Learning',
                            0.15,
                            Colors.orange,
                            '15%',
                          ),
                        ],
                      ),
                    ),
                  ),
                        const SizedBox(height: 80), // Bottom padding for nav bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
                // // Contact support
                // MoonsCard(
                //   child: ListTile(
                //     leading: const Icon(Icons.support_agent, color: Colors.blue),
                //     title: const Text('Liên hệ hỗ trợ'),
                //     subtitle: const Text('Nhận trợ giúp từ đội ngũ'),
                //     onTap: () {},
                //   ),
                // ),
                // const SizedBox(height: 8),
                // // Request new feature
                // MoonsCard(
                //   child: ListTile(
                //     leading: const Icon(Icons.lightbulb, color: Colors.amber),
                //     title: const Text('Đề xuất tính năng mới'),
                //     subtitle: const Text('Gửi ý tưởng cho ứng dụng'),
                //     onTap: () {},
                //   ),

  Widget _buildMasteryBar(String label, double value, Color color, String percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
