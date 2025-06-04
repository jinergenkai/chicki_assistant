import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chickies_ui/chickies_ui.dart';
import 'package:chicki_buddy/models/friend.dart';
import 'package:chicki_buddy/services/notification_service.dart';
import 'package:chicki_buddy/ui/screens/main_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(FriendAdapter());
  await Hive.openBox<Friend>('friends');

  // Initialize Notifications
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Birthday App',
      theme: ChickiesTheme.light(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
