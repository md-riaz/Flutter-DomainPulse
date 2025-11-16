import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'domain_check_service.dart';
import 'notification_service.dart';
import 'debug_log_service.dart';
import 'storage_service.dart';
import 'alarm_diagnostic_service.dart';
import 'alarm_permission_service.dart';
import '../models/debug_log.dart';

class AlarmService {
  static Future<void> scheduleAlarm(
    int alarmId,
    Duration interval,
    String domainUrl,
  ) async {
    try {
      // Log attempt with full details
      await AlarmDiagnosticService.logScheduleAttempt(
        alarmId: alarmId,
        interval: interval,
        domainUrl: domainUrl,
      );
      
      // Check if alarm permission is granted (critical for Android 12+/14+/15+)
      final hasPermission = await AlarmPermissionService.checkAlarmPermission();
      
      if (!hasPermission) {
        // Log the permission issue
        await DebugLogService.addLog(
          LogLevel.warning,
          'Alarm permission not granted - attempting to request',
          details: 'Alarm ID: $alarmId\nDomain: $domainUrl\nThis is required for Android 12+ devices',
        );
        
        // Try to request permission
        final granted = await AlarmPermissionService.requestAlarmPermission();
        
        if (!granted) {
          // Permission denied - log error and provide guidance
          await DebugLogService.addLog(
            LogLevel.error,
            'Failed to schedule alarm - permission denied',
            details: '''Alarm ID: $alarmId
Domain: $domainUrl
Reason: SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM permission not granted

ACTION REQUIRED:
1. Go to Settings → Apps → DomainPulse
2. Look for "Alarms & reminders" or "Schedule exact alarms"
3. Enable this permission
4. Return to the app and add the domain again

This permission is required on Android 12+ (API 31+) for exact alarm scheduling.''',
          );
          
          debugPrint('Alarm permission denied for $domainUrl');
          return; // Don't schedule alarm without permission
        }
        
        // Permission was just granted
        await DebugLogService.addLog(
          LogLevel.success,
          'Alarm permission granted - proceeding with scheduling',
          details: 'Alarm ID: $alarmId\nDomain: $domainUrl',
        );
      } else {
        // Log that permission is already granted
        await DebugLogService.addLog(
          LogLevel.info,
          'Alarm permission verified',
          details: 'Alarm ID: $alarmId\nDomain: $domainUrl\nPermission status: Granted',
        );
      }
      
      // Now schedule the alarm with permission confirmed
      await AndroidAlarmManager.periodic(
        interval,
        alarmId,
        _alarmCallback,
        wakeup: true,
        rescheduleOnReboot: true,
        exact: true,
        allowWhileIdle: true,
      );
      debugPrint('Alarm scheduled for $domainUrl with interval $interval');
      
      await AlarmDiagnosticService.logScheduleSuccess(
        alarmId: alarmId,
        interval: interval,
        domainUrl: domainUrl,
      );
      
      await AlarmDiagnosticService.logExpectedAlarmTime(
        alarmId: alarmId,
        interval: interval,
      );
    } catch (e, stackTrace) {
      debugPrint('Error scheduling alarm: $e');
      debugPrint('Stack trace: $stackTrace');
      
      await DebugLogService.addLog(
        LogLevel.error,
        'Failed to schedule alarm for: $domainUrl',
        details: 'Alarm ID: $alarmId\nInterval: $interval\nError: $e\nStack trace: $stackTrace',
      );
    }
  }

  static Future<void> cancelAlarm(int alarmId) async {
    try {
      await AndroidAlarmManager.cancel(alarmId);
      debugPrint('Alarm cancelled: $alarmId');
      
      await DebugLogService.addLog(
        LogLevel.info,
        'Alarm cancelled',
        details: 'Alarm ID: $alarmId',
      );
    } catch (e) {
      debugPrint('Error cancelling alarm: $e');
      
      await DebugLogService.addLog(
        LogLevel.error,
        'Failed to cancel alarm',
        details: 'Alarm ID: $alarmId\nError: $e',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    debugPrint('=== ALARM CALLBACK TRIGGERED ===');
    debugPrint('Timestamp: ${DateTime.now().toUtc()}');
    
    try {
      // Initialize Flutter engine for background execution
      debugPrint('Initializing Flutter binding...');
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('Flutter binding initialized');
      
      // Initialize storage service first (required for debug logs and domain checks)
      debugPrint('Initializing storage service...');
      await StorageService.init();
      debugPrint('Storage service initialized');
      
      // Initialize debug log service
      debugPrint('Initializing debug log service...');
      await DebugLogService.init();
      debugPrint('Debug log service initialized');
      
      // Initialize notification service for background notifications
      debugPrint('Initializing notification service...');
      await NotificationService.initialize();
      debugPrint('Notification service initialized');
      
      // Log alarm trigger - THIS IS CRITICAL FOR DEBUGGING
      // If users don't see this log, the alarm callback is not executing
      debugPrint('Adding log entry for alarm trigger...');
      await DebugLogService.addLog(
        LogLevel.info,
        'Background alarm triggered',
        details: '''Alarm callback started at ${DateTime.now().toUtc()}
Flutter binding: Initialized
Storage service: Initialized
Debug log service: Initialized
Notification service: Initialized
About to check domains...

If you see this message, the alarm IS firing correctly.
If you DON\'T see this message, check:
1. Alarm permission (Settings → Apps → DomainPulse → Alarms & reminders)
2. Battery optimization (Settings → Battery → disable for DomainPulse)
3. Background restrictions (Settings → Apps → DomainPulse → Battery → No restrictions)''',
      );
      debugPrint('Log entry added for alarm trigger');
      
      // Check all domains (StorageService already initialized)
      debugPrint('Starting domain check cycle...');
      await DomainCheckService.checkAllDomains();
      debugPrint('Domain check cycle completed');
      
      // Log successful completion
      await DebugLogService.addLog(
        LogLevel.success,
        'Background alarm completed successfully',
        details: 'All domains checked at ${DateTime.now().toUtc()}\nNext alarm will fire after the configured interval.',
      );
      
      debugPrint('=== ALARM CALLBACK COMPLETED SUCCESSFULLY ===');
    } catch (e, stackTrace) {
      debugPrint('!!! ERROR IN ALARM CALLBACK !!!');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Log the error - this is important for debugging
      try {
        // Ensure debug log service is initialized before trying to log
        await DebugLogService.init();
        await DebugLogService.addLog(
          LogLevel.error,
          'Background alarm failed',
          details: '''Error occurred in background alarm at ${DateTime.now().toUtc()}
Error: $e
Stack trace: $stackTrace

This error prevented the domain check from completing.
Please check the error details above.''',
        );
      } catch (logError) {
        debugPrint('Failed to log error: $logError');
      }
      
      // Don't rethrow - allow alarm to complete and schedule next run
    }
  }
}
