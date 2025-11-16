import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'domain_check_service.dart';
import 'notification_service.dart';
import 'debug_log_service.dart';
import '../models/debug_log.dart';

class AlarmService {
  static Future<void> scheduleAlarm(
    int alarmId,
    Duration interval,
    String domainUrl,
  ) async {
    try {
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
      
      await DebugLogService.addLog(
        LogLevel.success,
        'Alarm scheduled for domain: $domainUrl',
        details: 'Alarm ID: $alarmId\nInterval: $interval',
      );
    } catch (e) {
      debugPrint('Error scheduling alarm: $e');
      
      await DebugLogService.addLog(
        LogLevel.error,
        'Failed to schedule alarm for: $domainUrl',
        details: 'Alarm ID: $alarmId\nError: $e',
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
    debugPrint('Alarm callback triggered');
    
    try {
      // Initialize Flutter engine for background execution
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize notification service for background notifications
      await NotificationService.initialize();
      
      // Log alarm trigger
      await DebugLogService.addLog(
        LogLevel.info,
        'Background alarm triggered',
        details: 'Alarm callback started at ${DateTime.now().toUtc()}',
      );
      
      // Check all domains (this will initialize StorageService internally)
      await DomainCheckService.checkAllDomains();
      
      // Log successful completion
      await DebugLogService.addLog(
        LogLevel.success,
        'Background alarm completed successfully',
        details: 'All domains checked at ${DateTime.now().toUtc()}',
      );
      
      debugPrint('Alarm callback completed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error in alarm callback: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Log the error
      await DebugLogService.addLog(
        LogLevel.error,
        'Background alarm failed',
        details: 'Error: $e\nStack trace: $stackTrace',
      );
      
      // Don't rethrow - allow alarm to complete and schedule next run
    }
  }
}
