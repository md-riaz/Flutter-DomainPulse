import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'rdap_service.dart';
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
      
      // Fetch domain expiry via RDAP
      final expiryDate = await RdapService.getDomainExpiry(domain.url);

      // Update domain with new check time and expiry
      final updatedDomain = domain.copyWith(
        lastChecked: DateTime.now().toUtc(),
        expiryDate: expiryDate,
      );
      await StorageService.updateDomain(updatedDomain);

      // Check if domain is expiring soon or expired (all in UTC)
      if (expiryDate != null) {
        final now = DateTime.now().toUtc();
        final notifyThreshold = now.add(domain.notifyBeforeExpiry);

        if (expiryDate.isBefore(notifyThreshold)) {
          String message;
          String title;
          
          if (expiryDate.isBefore(now)) {
            // Domain has expired
            final daysExpired = now.difference(expiryDate).inDays;
            title = 'Domain EXPIRED: ${domain.url}';
            message = 'Domain ${domain.url} expired ${daysExpired} day${daysExpired != 1 ? 's' : ''} ago on ${_formatDate(expiryDate)} UTC.';
          } else {
            // Domain expiring soon
            final daysLeft = expiryDate.difference(now).inDays;
            title = 'Domain expiring soon: ${domain.url}';
            message = 'Domain ${domain.url} expires on ${_formatDate(expiryDate)} UTC (in $daysLeft day${daysLeft != 1 ? 's' : ''}).';
          }

          await NotificationService.sendNotification(
            ntfyTopic,
            title,
            message,
          );
        }
      }

      debugPrint('Domain check completed for ${domain.url}');
    } catch (e) {
      debugPrint('Error checking domain ${domain.url}: $e');
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
