import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../models/domain.dart';

class DomainCheckService {
  static Future<void> checkAllDomains() async {
    debugPrint('Checking all domains...');
    await StorageService.init();

    final domains = await StorageService.getDomains();
    final ntfyTopic = await StorageService.getNtfyTopic();

    if (ntfyTopic == null) {
      debugPrint('No ntfy topic configured');
      return;
    }

    for (final domain in domains) {
      await _checkDomain(domain, ntfyTopic);
    }
  }

  static Future<void> _checkDomain(Domain domain, String ntfyTopic) async {
    try {
      debugPrint('Checking domain: ${domain.url}');
      
      // Perform HEAD request to check domain
      final response = await http.head(
        Uri.parse('https://${domain.url}'),
        headers: {'User-Agent': 'DomainPulse/1.0'},
      ).timeout(const Duration(seconds: 10));

      // Parse expiry date from headers
      DateTime? expiryDate;
      final expires = response.headers['expires'];
      if (expires != null) {
        expiryDate = DateTime.tryParse(expires);
      }

      // Update domain with new check time and expiry
      final updatedDomain = domain.copyWith(
        lastChecked: DateTime.now(),
        expiryDate: expiryDate,
      );
      await StorageService.updateDomain(updatedDomain);

      // Check if domain is expiring soon or expired
      if (expiryDate != null) {
        final now = DateTime.now();
        final oneHourFromNow = now.add(const Duration(hours: 1));

        if (expiryDate.isBefore(oneHourFromNow)) {
          String message;
          if (expiryDate.isBefore(now)) {
            message = 'Domain ${domain.url} has expired!';
          } else {
            final minutesLeft = expiryDate.difference(now).inMinutes;
            message = 'Domain ${domain.url} expires in $minutesLeft minutes!';
          }

          await NotificationService.sendNotification(
            ntfyTopic,
            'Domain Expiry Alert',
            message,
          );
        }
      }

      debugPrint('Domain check completed for ${domain.url}');
    } catch (e) {
      debugPrint('Error checking domain ${domain.url}: $e');
    }
  }
}
