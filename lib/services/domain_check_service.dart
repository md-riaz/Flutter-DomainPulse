import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'rdap_service.dart';
import 'debug_log_service.dart';
import '../models/domain.dart';
import '../models/debug_log.dart';

class DomainCheckService {
  static Future<void> checkAllDomains() async {
    debugPrint('Checking all domains...');
    await StorageService.init();

    final domains = await StorageService.getDomains();
    
    await DebugLogService.addLog(
      LogLevel.info,
      'Starting domain check cycle',
      details: 'Checking ${domains.length} domain(s)',
    );

    for (final domain in domains) {
      await _checkDomain(domain);
    }
    
    await DebugLogService.addLog(
      LogLevel.success,
      'Domain check cycle completed',
      details: 'Checked ${domains.length} domain(s) successfully',
    );
  }

  static Future<void> _checkDomain(Domain domain) async {
    try {
      debugPrint('Checking domain: ${domain.url} (Mode: ${domain.monitoringMode.name})');
      
      await DebugLogService.addLog(
        LogLevel.info,
        'Checking domain: ${domain.url}',
        details: 'Mode: ${domain.monitoringMode.name}, Check interval: ${domain.checkInterval}',
      );
      
      DateTime? expiryDate;
      bool? isAvailable;
      
      // Fetch domain expiry via RDAP if monitoring expiry
      if (domain.monitoringMode == MonitoringMode.expiryOnly || 
          domain.monitoringMode == MonitoringMode.both) {
        expiryDate = await RdapService.getDomainExpiry(domain.url);
      }
      
      // Check domain availability if monitoring availability
      if (domain.monitoringMode == MonitoringMode.availabilityOnly || 
          domain.monitoringMode == MonitoringMode.both) {
        isAvailable = await RdapService.isDomainAvailable(domain.url);
      }

      // Track if domain became available
      final wasUnavailable = domain.isAvailable == false;
      final isNowAvailable = isAvailable == true;

      // Update domain with new check time, expiry, and availability
      final updatedDomain = domain.copyWith(
        lastChecked: DateTime.now().toUtc(),
        expiryDate: expiryDate ?? domain.expiryDate,
        isAvailable: isAvailable ?? domain.isAvailable,
        lastAvailabilityCheck: isAvailable != null ? DateTime.now().toUtc() : domain.lastAvailabilityCheck,
      );
      await StorageService.updateDomain(updatedDomain);

      // Check if domain is expiring soon or expired (all in UTC)
      // Only check expiry notifications if monitoring expiry
      if (expiryDate != null && 
          (domain.monitoringMode == MonitoringMode.expiryOnly || 
           domain.monitoringMode == MonitoringMode.both)) {
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
          await DebugLogService.addLog(
            LogLevel.info,
            'Attempting to send expiry notification',
            details: 'Domain: ${domain.url}\nTitle: $title\nMessage: $message',
          );
          
          final notificationSent = await NotificationService.sendNotification(
            title,
            message,
            type: NotificationType.expiry,
          );
          
          if (notificationSent) {
            await DebugLogService.addLog(
              LogLevel.success,
              'Expiry notification sent successfully',
              details: 'Domain: ${domain.url}\nTitle: $title',
            );
          } else {
            await DebugLogService.addLog(
              LogLevel.warning,
              'Failed to send expiry notification',
              details: 'Domain: ${domain.url}\nTitle: $title\nMessage: $message\n\nPossible reasons:\n- Notification permission not granted\n- Notification service initialization failed\n\nPlease check notification permissions in Settings → Apps → DomainPulse → Permissions → Notifications',
            );
          }
        } else {
          // Log why notification was not sent
          final now = DateTime.now().toUtc();
          String reason;
          if (domain.notifyBeforeExpiry == Duration.zero) {
            reason = 'Domain not yet expired (expires: ${_formatDateTimeAsiaDhaka(expiryDate)})';
          } else {
            final notifyThreshold = now.add(domain.notifyBeforeExpiry);
            final daysUntilThreshold = expiryDate.difference(notifyThreshold).inDays;
            reason = 'Domain not within notification window (notify ${domain.notifyBeforeExpiry.inDays} days before expiry, currently $daysUntilThreshold days until threshold)';
          }
          await DebugLogService.addLog(
            LogLevel.info,
            'No expiry notification needed',
            details: 'Domain: ${domain.url}\nExpiry: ${_formatDateTimeAsiaDhaka(expiryDate)}\nReason: $reason',
          );
        }
      }

      // Send notification if domain is available
      // Only check availability notifications if monitoring availability
      if (domain.monitoringMode == MonitoringMode.availabilityOnly || 
          domain.monitoringMode == MonitoringMode.both) {
        if (isAvailable == true) {
          await DebugLogService.addLog(
            LogLevel.info,
            'Domain is available - attempting notification',
            details: 'Domain: ${domain.url}\nStatus: Available for registration',
          );
          
          final notificationSent = await NotificationService.sendNotification(
            'Domain Available: ${domain.url}',
            'Domain ${domain.url} is available for registration! Act fast to secure it before someone else does.',
            type: NotificationType.availability,
          );
          
          if (notificationSent) {
            await DebugLogService.addLog(
              LogLevel.success,
              'Availability notification sent successfully',
              details: 'Domain: ${domain.url}',
            );
          } else {
            await DebugLogService.addLog(
              LogLevel.warning,
              'Failed to send availability notification',
              details: 'Domain: ${domain.url}\n\nPossible reasons:\n- Notification permission not granted\n- Notification service initialization failed\n\nPlease check notification permissions in Settings → Apps → DomainPulse → Permissions → Notifications',
            );
          }
        } else {
          // Log availability check status when no notification is needed
          String reason;
          if (isAvailable == false) {
            reason = 'Domain is registered (not available)';
          } else {
            reason = 'Availability status unknown (check may have failed)';
          }
          
          await DebugLogService.addLog(
            LogLevel.info,
            'No availability notification needed',
            details: 'Domain: ${domain.url}\nReason: $reason',
          );
        }
      }

      debugPrint('Domain check completed for ${domain.url}');
      
      // Log successful check with results
      String resultDetails = 'Domain: ${domain.url}';
      if (expiryDate != null) {
        resultDetails += '\nExpiry: ${_formatDateTimeAsiaDhaka(expiryDate)}';
      }
      if (isAvailable != null) {
        resultDetails += '\nAvailable: ${isAvailable ? "Yes" : "No"}';
      }
      
      await DebugLogService.addLog(
        LogLevel.success,
        'Domain check completed: ${domain.url}',
        details: resultDetails,
      );
    } catch (e) {
      debugPrint('Error checking domain ${domain.url}: $e');
      
      await DebugLogService.addLog(
        LogLevel.error,
        'Domain check failed: ${domain.url}',
        details: 'Error: $e',
      );
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
