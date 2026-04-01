import 'debug_log_service.dart';
import '../models/debug_log.dart';

/// Backward-compatible diagnostics service.
/// Reports WorkManager-based scheduling status for existing diagnostics UI.
class AlarmDiagnosticService {
  static Future<Map<String, dynamic>> runDiagnostics() async {
    // Legacy keys retained to avoid broader UI refactors in this migration.
    final results = <String, dynamic>{
      'alarm_manager_initialized': true,
      'alarm_permission_granted': true,
      'alarm_permission_message':
          'Exact alarm permission is not required with WorkManager scheduling.',
      'checks_performed': DateTime.now().toUtc().toIso8601String(),
    };

    await DebugLogService.addLog(
      LogLevel.info,
      'Running background diagnostics',
      details: 'WorkManager scheduling path active',
    );
    return results;
  }

  static Future<void> logScheduleAttempt({
    required int alarmId,
    required Duration interval,
    required String domainUrl,
  }) async {
    await DebugLogService.addLog(
      LogLevel.info,
      'Background sync registration requested',
      details:
          'Domain: $domainUrl\nInterval request: $interval\nLegacy alarmId: $alarmId',
    );
  }

  static Future<void> logScheduleSuccess({
    required int alarmId,
    required Duration interval,
    required String domainUrl,
  }) async {
    await DebugLogService.addLog(
      LogLevel.success,
      'Background sync registration completed',
      details:
          'Domain: $domainUrl\nInterval request: $interval\nLegacy alarmId: $alarmId',
    );
  }

  static Future<void> logExpectedAlarmTime({
    required int alarmId,
    required Duration interval,
  }) async {
    await DebugLogService.addLog(
      LogLevel.info,
      'WorkManager handles next execution window',
      details: 'Legacy alarmId: $alarmId\nRequested interval: $interval',
    );
  }
}
