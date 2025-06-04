import 'package:flutter/material.dart';
import 'package:chickies_ui/chickies_ui.dart';
import 'package:chicki_buddy/ui/screens/birthday_list_screen.dart';
import 'package:chicki_buddy/ui/screens/chat_screen.dart';
import 'package:chicki_buddy/ui/screens/birthday_calendar_screen.dart';
import 'package:chicki_buddy/ui/screens/gift_suggestions_screen.dart';
import 'package:chicki_buddy/ui/screens/settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: const TabBarView(
          children: [
            ChatScreen(),
            BirthdayCalendarScreen(),
            BirthdayListScreen(),
            GiftSuggestionsScreen(),
            SettingsScreen(),
          ],
        ),
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
            child: TabBar(
              tabs: [
                _buildTab(Icons.chat, 'Chicki'),
                _buildTab(Icons.calendar_month, 'Lịch'),
                _buildTab(Icons.cake, 'Sinh nhật'),
                _buildTab(Icons.card_giftcard, 'Quà tặng'),
                _buildTab(Icons.settings, 'Cài đặt'),
              ],
              labelStyle: const TextStyle(fontSize: 12),
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Theme.of(context).colorScheme.primary,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 4),
              labelPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
      ),
    );
  }
}
