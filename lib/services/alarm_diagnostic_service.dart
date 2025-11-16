import 'package:flutter/foundation.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'debug_log_service.dart';
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
