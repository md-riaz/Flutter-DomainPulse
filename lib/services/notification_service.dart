import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    _initialized = true;
    debugPrint('Notification service initialized');
  }

  static Future<void> sendNotification(
    String title,
    String message,
  ) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'domain_expiry_channel',
        'Domain Expiry Notifications',
        channelDescription: 'Notifications for domain expiration alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        message,
        notificationDetails,
      );

      debugPrint('Local notification sent: $title');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
