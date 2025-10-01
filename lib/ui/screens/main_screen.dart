import 'package:chicki_buddy/ui/screens/assistant_settings_screen.dart';
import 'package:chicki_buddy/ui/screens/chicky_screen.dart';
import 'package:chicki_buddy/ui/screens/flash_card.screen.dart';
import 'package:chicki_buddy/ui/screens/model_test.screen.dart';
import 'package:chicki_buddy/ui/screens/sherpa_tts_test_screen.dart';
import 'package:chicki_buddy/ui/screens/super_action.screen.dart';
import 'package:chicki_buddy/ui/screens/test_buddy.screen.dart';
import 'package:chicki_buddy/ui/screens/vocabulary.screen.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import 'chat_screen.dart';
import 'birthday_calendar_screen.dart';
import 'birthday_list_screen.dart';
import 'gift_suggestions_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SherpaTtsTestScreen(),
    AssistantSettingsScreen(),
    ChickyScreen(),
    BirthdayCalendarScreen(),
    BirthdayListScreen(),
    SuperControlScreen(),
    VocabularyListScreen(),
    SettingsScreen(),
    FlashCardScreen(),
    ModelTestScreen(),
    TestBuddyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.moonColors!.gohan,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MoonNavBarItem(
                icon: MoonIcons.chat_chat_16_regular,
                label: 'Chicki',
                selected: _currentIndex == 0,
                onTap: () => _onNavBarTap(0),
              ),
              _MoonNavBarItem(
                icon: Icons.calendar_month,
                label: 'Lịch',
                selected: _currentIndex == 1,
                onTap: () => _onNavBarTap(1),
              ),
              _MoonNavBarItem(
                icon: Icons.book_rounded,
                label: 'Card',
                selected: _currentIndex == 2,
                onTap: () => _onNavBarTap(2),
              ),
              _MoonNavBarItem(
                icon: Icons.card_giftcard,
                label: 'Quà tặng',
                selected: _currentIndex == 3,
                onTap: () => _onNavBarTap(3),
              ),
              _MoonNavBarItem(
                icon: Icons.settings,
                label: 'Cài đặt',
                selected: _currentIndex == 4,
                onTap: () => _onNavBarTap(4),
              ),
              _MoonNavBarItem(
                icon: Icons.settings,
                label: 'Cài đặt',
                selected: _currentIndex == 5,
                onTap: () => _onNavBarTap(5),
              ),
              _MoonNavBarItem(
                icon: Icons.science,
                label: 'Test Buddy',
                selected: _currentIndex == 6,
                onTap: () => _onNavBarTap(6),
              ),
              _MoonNavBarItem(
                icon: Icons.science,
                label: 'Test Buddy',
                selected: _currentIndex == 6,
                onTap: () => _onNavBarTap(6),
              ),
              _MoonNavBarItem(
                icon: Icons.science,
                label: 'Test Buddy',
                selected: _currentIndex == 6,
                onTap: () => _onNavBarTap(6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoonNavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoonNavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = context.moonColors!.piccolo;
    final Color unselectedColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: selected
            ? Container(
                decoration: BoxDecoration(
                  color: context.moonColors!.piccolo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 26,
                      color: selectedColor,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: selectedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Icon(
                icon,
                size: 26,
                color: unselectedColor,
              ),
      ),
    );
  }
}
