import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chicki_buddy/ui/screens/birthday_list_screen.dart';
import 'package:chicki_buddy/ui/screens/chat_screen.dart';
import 'package:chicki_buddy/ui/screens/birthday_calendar_screen.dart';
import 'package:chicki_buddy/ui/screens/gift_suggestions_screen.dart';
import 'package:chicki_buddy/ui/screens/settings_screen.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  Widget _buildTab(IconData icon, String text) {
    return Tab(
      iconMargin: const EdgeInsets.only(bottom: 4),
      height: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          Text(
            text,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy index hiện tại từ location
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/calendar')) currentIndex = 1;
    else if (location.startsWith('/birthdays')) currentIndex = 2;
    else if (location.startsWith('/gifts')) currentIndex = 3;
    else if (location.startsWith('/settings')) currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/calendar');
                  break;
                case 2:
                  context.go('/birthdays');
                  break;
                case 3:
                  context.go('/gifts');
                  break;
                case 4:
                  context.go('/settings');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat),
                label: 'Chicki',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month),
                label: 'Lịch',
              ),
              NavigationDestination(
                icon: Icon(Icons.cake),
                label: 'Sinh nhật',
              ),
              NavigationDestination(
                icon: Icon(Icons.card_giftcard),
                label: 'Quà tặng',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Cài đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
