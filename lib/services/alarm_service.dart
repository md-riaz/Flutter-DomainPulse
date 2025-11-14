import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'domain_check_service.dart';

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
    } catch (e) {
      debugPrint('Error scheduling alarm: $e');
    }
  }

  static Future<void> cancelAlarm(int alarmId) async {
    try {
      await AndroidAlarmManager.cancel(alarmId);
      debugPrint('Alarm cancelled: $alarmId');
    } catch (e) {
      debugPrint('Error cancelling alarm: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    debugPrint('Alarm callback triggered');
    await DomainCheckService.checkAllDomains();
  }
}
