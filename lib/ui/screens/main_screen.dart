import 'package:chicki_buddy/ui/screens/assistant_settings_screen.dart';
import 'package:chicki_buddy/ui/screens/books_screen.dart';
import 'package:chicki_buddy/ui/screens/chicky_screen.dart';
import 'package:chicki_buddy/ui/screens/intent_test_screen.dart';
import 'package:chicki_buddy/ui/screens/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChickyScreen(),           
    IntentTestScreen(),
    // AssistantSettingsScreen(), 
    BooksScreen(),
    UserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onNavBarTap(int index) {
    if (index < 0 || index >= _screens.length) return; // tránh crash nếu index vượt quá
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
        body: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          itemCount: _screens.length,
          itemBuilder: (context, index) => _screens[index],
        ),
        bottomNavigationBar: FractionallySizedBox(
              widthFactor: 0.70, // 60% of screen width

          child: LayoutBuilder(
            builder: (context, constraints) {
              final double tabWidth = (constraints.maxWidth) / 4;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: context.moonColors!.gohan,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MoonNavBarItem(
                        icon: LucideIcons.bot, // Chat cute
                        selected: _currentIndex == 0,
                        onTap: () => _onNavBarTap(0),
                        width: tabWidth,
                      ),
                      _MoonNavBarItem(
                        icon: LucideIcons.wrench, // Setup learning (icon đẹp hơn setting)
                        selected: _currentIndex == 1,
                        onTap: () => _onNavBarTap(1),
                        width: tabWidth,
                      ),
                      _MoonNavBarItem(
                        icon: LucideIcons.shoppingBag, // Bookstore, library
                        selected: _currentIndex == 2,
                        onTap: () => _onNavBarTap(2),
                        width: tabWidth,
                      ),
                      _MoonNavBarItem(
                        icon: LucideIcons.user2, // User, personal
                        selected: _currentIndex == 3,
                        onTap: () => _onNavBarTap(3),
                        width: tabWidth,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MoonNavBarItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  final double? width;

  const _MoonNavBarItem({
    required this.icon,
    this.label,
    required this.selected,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    const Color selectedIconColor = Colors.white;
    const Color unselectedIconColor = Colors.black;
    const Color selectedBgColor = Colors.black;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: selected
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: selectedIconColor,
                      ),
                      const SizedBox(height: 2),
                      label != null
                          ? Text(
                        label!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: selectedIconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ) : const SizedBox.shrink(),
                    ],
                  ),
                ),
              )
            : Container(
                 width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 22,
                  color: unselectedIconColor,
                ),
              ),
      ),
    );
  }
}
