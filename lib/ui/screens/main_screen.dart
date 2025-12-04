import 'package:chicki_buddy/ui/screens/assistant_settings_screen.dart';
import 'package:chicki_buddy/ui/screens/books_screen.dart';
import 'package:chicki_buddy/ui/screens/chicky_screen.dart';
import 'package:chicki_buddy/ui/screens/debug_screen.dart';
import 'package:chicki_buddy/ui/screens/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  late AnimationController _navBarAnimationController;
  late Animation<Offset> _navBarSlideAnimation;
  double _lastScrollOffset = 0;

  final List<Widget> _screens = const [
    ChickyScreen(),
    // AssistantSettingsScreen(),
    DebugScreen(),
    BooksScreen(),
    UserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    _navBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _navBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(
      parent: _navBarAnimationController,
      curve: Curves.easeInOut,
    ));
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

  bool _handleScrollNotification(ScrollNotification notification) {
    // Only handle vertical scroll from child screens, not horizontal PageView scroll
    if (notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.vertical &&
        notification.depth > 0) {

      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;

      if (delta < -5 && !_isNavBarVisible) {
        // Scrolling up - show nav bar
        setState(() => _isNavBarVisible = true);
        _navBarAnimationController.reverse();
      } else if (delta > 5 && _isNavBarVisible && currentOffset > 50) {
        // Scrolling down - hide nav bar (only if scrolled past 50px)
        setState(() => _isNavBarVisible = false);
        _navBarAnimationController.forward();
      }

      _lastScrollOffset = currentOffset;
    }
    return false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navBarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemCount: _screens.length,
            itemBuilder: (context, index) => _screens[index],
          ),
        ),
        bottomNavigationBar: SlideTransition(
          position: _navBarSlideAnimation,
          child: FractionallySizedBox(
            widthFactor: 0.68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double tabWidth = (constraints.maxWidth) / 4;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MoonNavBarItem(
                          icon: LucideIcons.bot,
                          selected: _currentIndex == 0,
                          onTap: () => _onNavBarTap(0),
                          width: tabWidth,
                        ),
                        _MoonNavBarItem(
                          icon: LucideIcons.wrench,
                          selected: _currentIndex == 1,
                          onTap: () => _onNavBarTap(1),
                          width: tabWidth,
                        ),
                        _MoonNavBarItem(
                          icon: LucideIcons.shoppingBag,
                          selected: _currentIndex == 2,
                          onTap: () => _onNavBarTap(2),
                          width: tabWidth,
                        ),
                        _MoonNavBarItem(
                          icon: LucideIcons.user2,
                          selected: _currentIndex == 3,
                          onTap: () => _onNavBarTap(3),
                          width: tabWidth,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ));
  }
}

class _MoonNavBarItem extends StatefulWidget {
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
  State<_MoonNavBarItem> createState() => _MoonNavBarItemState();
}

class _MoonNavBarItemState extends State<_MoonNavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color unselectedIconColor = Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        _animationController.forward().then((_) => _animationController.reverse());
        widget.onTap();
      },
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: widget.selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 22,
                    color: widget.selected ? Colors.white : unselectedIconColor,
                  ),
                  if (widget.label != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.selected ? Colors.white : unselectedIconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
