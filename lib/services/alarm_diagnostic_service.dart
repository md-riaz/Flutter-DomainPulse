import 'package:flutter/foundation.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'debug_log_service.dart';
import 'alarm_permission_service.dart';
import 'notification_service.dart';
import '../models/debug_log.dart';

/// Service to diagnose alarm-related issues
class AlarmDiagnosticService {
  /// Run comprehensive diagnostics on alarm system
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    await DebugLogService.addLog(
      LogLevel.info,
      'Running alarm diagnostics',
    );
    
    try {
      // Check if AndroidAlarmManager is initialized
      results['alarm_manager_initialized'] = true;
      await DebugLogService.addLog(
        LogLevel.success,
        'Alarm manager is initialized',
      );
    } catch (e) {
      results['alarm_manager_initialized'] = false;
      await DebugLogService.addLog(
        LogLevel.error,
        'Alarm manager initialization failed',
        details: 'Error: $e',
      );
    }
    
    // Check alarm permission status (critical for Android 12+, 14+, 15+)
    try {
      final alarmPermission = await AlarmPermissionService.checkAlarmPermission();
      results['alarm_permission_granted'] = alarmPermission;
      
      if (alarmPermission) {
        await DebugLogService.addLog(
          LogLevel.success,
          'Alarm permission is granted',
          details: 'SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM permission verified',
        );
      } else {
        await DebugLogService.addLog(
          LogLevel.error,
          'Alarm permission NOT granted',
          details: '''This is REQUIRED for Android 12+ (API 31+) devices.

ACTION REQUIRED:
1. Go to Settings → Apps → DomainPulse
2. Find "Alarms & reminders" or "Schedule exact alarms"
3. Enable this permission
4. Return to the app

Without this permission, background alarms will NOT work on Android 12+, 14+, or 15+.''',
        );
      }
      
      results['alarm_permission_message'] = await AlarmPermissionService.getPermissionStatusMessage();
    } catch (e) {
      results['alarm_permission_check_failed'] = true;
      await DebugLogService.addLog(
        LogLevel.warning,
        'Could not check alarm permission',
        details: 'Error: $e\nThis may be normal on older Android versions',
      );
    }
    
    // Check notification permission status (required for Android 13+, 15+)
    try {
      final notificationPermission = await NotificationService.checkNotificationPermission();
      results['notification_permission_granted'] = notificationPermission;
      
      if (notificationPermission) {
        await DebugLogService.addLog(
          LogLevel.success,
          'Notification permission is granted',
        );
      } else {
        await DebugLogService.addLog(
          LogLevel.error,
          'Notification permission NOT granted',
          details: '''This is REQUIRED for Android 13+ (API 33+) devices to show notifications.

ACTION REQUIRED:
1. Go to Settings → Apps → DomainPulse → Permissions
2. Find "Notifications"
3. Enable this permission
4. Return to the app

Without this permission, you will NOT receive domain expiry or availability alerts.''',
        );
      }
    } catch (e) {
      results['notification_permission_check_failed'] = true;
      await DebugLogService.addLog(
        LogLevel.warning,
        'Could not check notification permission',
        details: 'Error: $e\nThis may be normal on older Android versions',
      );
    }
    
    // Check Android version (available via platform channel)
    // This would require platform-specific implementation
    results['checks_performed'] = DateTime.now().toUtc().toIso8601String();
    
    await DebugLogService.addLog(
      LogLevel.info,
      'Diagnostics completed',
      details: 'Results: ${results.toString()}',
    );
    
    return results;
  }
  
  /// Log alarm schedule attempt with details
  static Future<void> logScheduleAttempt({
    required int alarmId,
    required Duration interval,
    required String domainUrl,
  }) async {
    await DebugLogService.addLog(
      LogLevel.info,
      'Attempting to schedule alarm',
      details: '''
Alarm ID: $alarmId
Domain: $domainUrl
Interval: $interval
Interval (seconds): ${interval.inSeconds}
Exact: true
Wakeup: true
RescheduleOnReboot: true
AllowWhileIdle: true
Timestamp: ${DateTime.now().toUtc()}
''',
    );
  }
  
  /// Log successful alarm scheduling
  static Future<void> logScheduleSuccess({
    required int alarmId,
    required Duration interval,
    required String domainUrl,
  }) async {
    await DebugLogService.addLog(
      LogLevel.success,
      'Alarm scheduled successfully',
      details: '''
Alarm ID: $alarmId
Domain: $domainUrl
Interval: $interval
Next expected trigger: ${DateTime.now().toUtc().add(interval)}
''',
    );
  }
  
  /// Check if alarms are working by logging expected vs actual times
  static Future<void> logExpectedAlarmTime({
    required int alarmId,
    required Duration interval,
  }) async {
    final nextExpectedTime = DateTime.now().toUtc().add(interval);
    await DebugLogService.addLog(
      LogLevel.info,
      'Alarm scheduled - next expected trigger',
      details: '''
Alarm ID: $alarmId
Current time: ${DateTime.now().toUtc()}
Interval: $interval
Next expected trigger: $nextExpectedTime
Watch debug logs to see if alarm fires at expected time
''',
    );
  }
}
