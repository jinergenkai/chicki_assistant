import 'package:chicki_buddy/utils/permission_utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> showBirthdayNotification(String name) async {
    // Request notification permission for Android 13 and above
    await PermissionUtils.checkNotification();
    
    const androidDetails = AndroidNotificationDetails(
      'birthday_channel',
      'Trợ lý Chicki',
      channelDescription: 'Thông báo từ Trợ lý Chicki',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      playSound: true,
      icon: '@drawable/ic_stat_notify',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Chicki báo nè 🐥',
      'Mai gà con $name thổi nến\nCó quà chưa đó?',
      details,
    );
  }
}