import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
    
    // Request notification permission on Android 13+
    await requestNotificationPermission();
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    debugPrint('Notification permission status: $status');
    return status.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> sendNotification(
    String title,
    String message, {
    NotificationType type = NotificationType.expiry,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Check if permission is granted
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted');
        return false;
      }

      // Use appropriate channel based on notification type
      final androidDetails = type == NotificationType.expiry
          ? const AndroidNotificationDetails(
              'domain_expiry_channel',
              'Domain Expiry Notifications',
              channelDescription: 'Notifications for domain expiration alerts',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            )
          : const AndroidNotificationDetails(
              'domain_availability_channel',
              'Domain Availability Notifications',
              channelDescription: 'Notifications for domain availability alerts',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        message,
        notificationDetails,
      );

      debugPrint('Local notification sent: $title (${type.name})');
      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }
}

enum NotificationType {
  expiry,
  availability,
}
