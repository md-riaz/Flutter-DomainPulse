import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle SCHEDULE_EXACT_ALARM permission for Android 12+ (API 31+)
class AlarmPermissionService {
  /// Check if the alarm permission is granted
  /// On Android 12+ (API 31+), this checks SCHEDULE_EXACT_ALARM permission
  /// On older versions, returns true as the permission is not required
  static Future<bool> checkAlarmPermission() async {
    try {
      // For Android 12+ (API 31+), check scheduleExactAlarm permission
      final status = await Permission.scheduleExactAlarm.status;
      debugPrint('Alarm permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking alarm permission: $e');
      // If the permission doesn't exist (older Android), assume granted
      return true;
    }
  }

  /// Request the alarm permission
  /// On Android 12+ (API 31+), this opens the system settings for SCHEDULE_EXACT_ALARM
  /// On older versions, returns true as the permission is not required
  static Future<bool> requestAlarmPermission() async {
    try {
      // Check if permission is already granted
      final status = await Permission.scheduleExactAlarm.status;
      
      if (status.isGranted) {
        debugPrint('Alarm permission already granted');
        return true;
      }

      // Request the permission (this will open system settings on Android 12+)
      final result = await Permission.scheduleExactAlarm.request();
      debugPrint('Alarm permission request result: $result');
      
      return result.isGranted;
    } catch (e) {
      debugPrint('Error requesting alarm permission: $e');
      // If the permission doesn't exist (older Android), assume granted
      return true;
    }
  }

  /// Open the app settings where user can grant the alarm permission
  /// Useful when permission has been denied and needs to be granted manually
  static Future<bool> openAlarmSettings() async {
    try {
      debugPrint('Opening alarm permission settings');
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening alarm settings: $e');
      return false;
    }
  }

  /// Check if the device requires alarm permission (Android 12+)
  /// Returns true if running on Android 12+ (API 31+)
  /// 
  /// Note: This uses exception-based detection which is the recommended approach
  /// for permission_handler package, as it automatically handles API level differences
  /// without requiring explicit Android SDK version checks.
  static Future<bool> requiresAlarmPermission() async {
    try {
      // Try to get the permission status
      // If this succeeds without throwing, the permission exists (Android 12+)
      final status = await Permission.scheduleExactAlarm.status;
      // Permission exists, so it's required on this device
      debugPrint('Alarm permission is required on this device, status: $status');
      return true;
    } catch (e) {
      // If checking the permission throws an error, the permission doesn't exist
      // This means we're on Android 11 or below where it's not required
      debugPrint('Alarm permission not required on this device: $e');
      return false;
    }
  }

  /// Get a user-friendly message about the alarm permission status
  static Future<String> getPermissionStatusMessage() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      
      if (status.isGranted) {
        return 'Alarm permission is granted. Background checks will work as expected.';
      } else if (status.isDenied) {
        return 'Alarm permission is not granted. Please grant the permission to enable background domain checks.';
      } else if (status.isPermanentlyDenied) {
        return 'Alarm permission is permanently denied. Please enable it manually in system settings.';
      } else if (status.isRestricted) {
        return 'Alarm permission is restricted by the system.';
      } else {
        return 'Alarm permission status is unknown.';
      }
    } catch (e) {
      // On Android versions that don't require this permission
      return 'Alarm permission is not required on this device.';
    }
  }
}
