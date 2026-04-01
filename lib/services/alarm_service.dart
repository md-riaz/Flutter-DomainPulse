import 'package:flutter/foundation.dart';
import 'workmanager_service.dart';

/// Backward-compatible scheduling façade.
/// Uses WorkManager periodic sync instead of per-domain exact alarms.
class AlarmService {
  static Future<void> scheduleAlarm(
    int alarmId,
    Duration interval,
    String domainUrl,
  ) async {
    // Legacy per-domain scheduling arguments are preserved for call-site compatibility.
    // WorkManager uses one shared periodic task and due-domain filtering.
    debugPrint(
      'Registering WorkManager sync (requested by $domainUrl, alarmId: $alarmId, interval: $interval)',
    );
    await WorkmanagerService.registerBackgroundSync();
  }

  static Future<void> cancelAlarm(int alarmId) async {
    debugPrint('Domain removed (alarmId: $alarmId). WorkManager sync remains active.');
  }

  static Future<void> rescheduleAllAlarms() async {
    await WorkmanagerService.registerBackgroundSync();
  }
}
