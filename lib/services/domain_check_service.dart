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

    for (final domain in domains) {
      await _checkDomain(domain);
    }
  }

  static Future<void> _checkDomain(Domain domain) async {
    try {
      debugPrint('Checking domain: ${domain.url}');
      
      // Fetch domain expiry via RDAP
      final expiryDate = await RdapService.getDomainExpiry(domain.url);
      
      // Check domain availability
      final isAvailable = await RdapService.isDomainAvailable(domain.url);

      // Track if domain became available
      final wasUnavailable = domain.isAvailable == false;
      final isNowAvailable = isAvailable == true;

      // Update domain with new check time, expiry, and availability
      final updatedDomain = domain.copyWith(
        lastChecked: DateTime.now().toUtc(),
        expiryDate: expiryDate,
        isAvailable: isAvailable,
        lastAvailabilityCheck: DateTime.now().toUtc(),
      );
      await StorageService.updateDomain(updatedDomain);

      // Check if domain is expiring soon or expired (all in UTC)
      if (expiryDate != null) {
        final now = DateTime.now().toUtc();
        bool shouldNotify = false;
        late String message;
        late String title;

        // Check notification timing setting
        if (domain.notifyBeforeExpiry == Duration.zero) {
          // Only notify after expiration
          if (expiryDate.isBefore(now)) {
            shouldNotify = true;
            final daysExpired = now.difference(expiryDate).inDays;
            title = 'Domain EXPIRED: ${domain.url}';
            message = 'Domain ${domain.url} expired ${daysExpired} day${daysExpired != 1 ? 's' : ''} ago on ${_formatDateTimeAsiaDhaka(expiryDate)}.';
          }
        } else {
          // Notify before expiration (existing behavior)
          final notifyThreshold = now.add(domain.notifyBeforeExpiry);
          if (expiryDate.isBefore(notifyThreshold)) {
            shouldNotify = true;
            if (expiryDate.isBefore(now)) {
              // Domain has expired
              final daysExpired = now.difference(expiryDate).inDays;
              title = 'Domain EXPIRED: ${domain.url}';
              message = 'Domain ${domain.url} expired ${daysExpired} day${daysExpired != 1 ? 's' : ''} ago on ${_formatDateTimeAsiaDhaka(expiryDate)}.';
            } else {
              // Domain expiring soon
              final daysLeft = expiryDate.difference(now).inDays;
              title = 'Domain expiring soon: ${domain.url}';
              message = 'Domain ${domain.url} expires on ${_formatDateTimeAsiaDhaka(expiryDate)} (in $daysLeft day${daysLeft != 1 ? 's' : ''}).';
            }
          }
        }

        if (shouldNotify) {
          await NotificationService.sendNotification(
            title,
            message,
          );
        }
      }

      // Send notification if domain became available
      if (wasUnavailable && isNowAvailable) {
        await NotificationService.sendNotification(
          'Domain Available: ${domain.url}',
          'Domain ${domain.url} is now available for registration! Act fast to secure it before someone else does.',
        );
      }

      debugPrint('Domain check completed for ${domain.url}');
    } catch (e) {
      debugPrint('Error checking domain ${domain.url}: $e');
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert UTC DateTime to Asia/Dhaka timezone (UTC+6) for display
  static DateTime _toAsiaDhaka(DateTime utcDate) {
    return utcDate.add(const Duration(hours: 6));
  }

  /// Format date with time in Asia/Dhaka timezone
  static String _formatDateTimeAsiaDhaka(DateTime utcDate) {
    final dhakaTime = _toAsiaDhaka(utcDate);
    return '${dhakaTime.year}-${dhakaTime.month.toString().padLeft(2, '0')}-${dhakaTime.day.toString().padLeft(2, '0')} '
           '${dhakaTime.hour.toString().padLeft(2, '0')}:${dhakaTime.minute.toString().padLeft(2, '0')} Asia/Dhaka';
  }
}
