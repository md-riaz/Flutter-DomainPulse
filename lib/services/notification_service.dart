import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> sendNotification(
    String topic,
    String title,
    String message,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://ntfy.sh/$topic'),
        headers: {
          'Title': title,
          'Priority': 'high',
          'Tags': 'warning',
        },
        body: message,
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
