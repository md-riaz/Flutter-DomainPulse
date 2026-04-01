import 'package:flutter/foundation.dart';

/// Legacy alarm permission service kept for UI compatibility.
/// WorkManager scheduling does not require exact alarm permission.
class AlarmPermissionService {
  static Future<bool> checkAlarmPermission() async {
    return true;
  }

  static Future<bool> requestAlarmPermission() async {
    return true;
  }

  static Future<bool> openAlarmSettings() async {
    try {
      debugPrint('Opening app settings');
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  static Future<bool> requiresAlarmPermission() async {
    return false;
  }

  static Future<String> getPermissionStatusMessage() async {
    return 'Exact alarm permission is not required with WorkManager scheduling.';
  }
}
