# Android 15 Notification and Alarm Fix

## Problem
On Android 15 (API 35), users reported that even after granting notification and alarm permissions, no notifications or alarms were triggered after 15 minutes, and debug logs remained empty.

## Root Causes
1. **Missing USE_EXACT_ALARM permission**: Android 14+ introduced `USE_EXACT_ALARM` as an alternative to `SCHEDULE_EXACT_ALARM` that doesn't require user approval for non-clock apps
2. **Missing FOREGROUND_SERVICE permission**: Android 14+ requires this permission for reliable background operations
3. **Missing USE_ALARM_ATTRIBUTES permission**: Android 15+ requires this permission for alarm scheduling attributes
4. **No permission verification**: The app wasn't explicitly checking if alarm permission was granted before scheduling alarms
5. **Insufficient debug logging**: The alarm callback didn't have enough logging to diagnose if it was executing
6. **Service initialization in background**: StorageService and DebugLogService were not properly initialized in background alarm callback context
7. **CRITICAL (v1.1.2)**: **Alarm callback was a static method instead of top-level function**: The `android_alarm_manager_plus` package requires callbacks to be top-level functions to be accessible from the background isolate. The callback was implemented as a static method within the `AlarmService` class, preventing it from being invoked.
8. **CRITICAL (v1.1.3)**: **Permission request in background context**: The notification service was calling `Permission.notification.request()` during background alarm execution, which requires an Android Activity context that doesn't exist in background. This caused "Unable to detect current Android Activity" crashes.

## Changes Made

### 1. AndroidManifest.xml
Added three new permissions:
- `USE_EXACT_ALARM`: Android 14+ permission that allows exact alarms without user approval
- `FOREGROUND_SERVICE`: Required for Android 14+ background operations
- `USE_ALARM_ATTRIBUTES`: Required for Android 15+ alarm scheduling attributes

### 2. Alarm Service (lib/services/alarm_service.dart)
- **Permission check before scheduling**: Now verifies alarm permission is granted before scheduling
- **Enhanced error messages**: Provides detailed, actionable guidance when permissions are missing
- **Comprehensive callback logging**: Added extensive debug logs to the alarm callback to verify execution
- **Permission request flow**: If permission isn't granted, tries to request it before scheduling
- **Service initialization**: Explicitly initializes StorageService and DebugLogService at the start of alarm callback
- **Enhanced background context**: All required services are now initialized before domain checks run
- **CRITICAL (v1.1.2)**: **Moved callback to top-level function**: Changed from `AlarmService._alarmCallback()` (static method) to `alarmCallback()` (top-level function) with `@pragma('vm:entry-point')` annotation. This is required by `android_alarm_manager_plus` to make the callback accessible from the background isolate.

### 3. Main App (lib/main.dart)
- **Await permission request**: Now waits for alarm permission request to complete before loading UI
- This ensures permissions are properly handled on app startup

### 4. Diagnostics (lib/services/alarm_diagnostic_service.dart)
- **Permission verification**: Diagnostics now check both alarm and notification permissions
- **Detailed status messages**: Shows permission status with actionable steps if not granted

### 5. Storage Service (lib/services/storage_service.dart)
- **Nullable path**: Changed `_dataPath` from `late` to nullable to prevent uninitialized access
- **Initialization guard**: Added check to prevent re-initialization
- **Null safety**: Added null checks in file getter methods with descriptive error messages
- **Background context**: Now properly handles initialization in background alarm callback

### 6. Debug Log Service (lib/services/debug_log_service.dart)
- **Always initialize**: Ensures `_dataPath` is initialized before file access
- **Null safety**: Added null check after init() to throw descriptive error if initialization fails
- **Debug logging**: Added debug print to track initialization path
- **Background context**: Now properly initializes in background alarm callback to persist logs

### 7. Domain Check Service (lib/services/domain_check_service.dart) - v1.1.2
- **Notification failure logging**: Now logs when notifications fail to send
- **Helpful troubleshooting**: Provides clear guidance about checking notification permissions
- **Both notification types**: Covers both expiry and availability notifications

### 8. Notification Service (lib/services/notification_service.dart) - v1.1.3
- **Background context detection**: Added optional `isBackgroundContext` parameter to `initialize()` method
- **Conditional permission request**: Only requests notification permission in foreground contexts (when Activity is available)
- **Background permission check**: In background contexts, only checks permission status without requesting
- **Fixes crash**: Prevents "Unable to detect current Android Activity" error during background alarm execution
- **Maintains behavior**: Foreground initialization unchanged - continues to request permission normally

### 9. Documentation
- Updated TROUBLESHOOTING.md with Android 15 specific guidance, v1.1.2 fix, and v1.1.3 fix information
- Updated README.md to mention Android 15 support
- Updated FEATURES.md with details about new permissions and fixes
- Updated ANDROID_15_FIX.md with service initialization fixes, v1.1.2 callback fix, and v1.1.3 permission fix

## How to Verify the Fix

### 1. Check Debug Logs for Permission Status
After installing the updated app:
1. Open the app
2. Tap the **bug report icon** (🐛) in the home screen
3. Look for these log entries:
   - "Alarm permission verified" or "Alarm permission granted"
   - If you see "Alarm permission not granted", follow the instructions in the log

### 2. Add a Domain and Watch Debug Logs
1. Clear debug logs (in Debug Logs screen)
2. Add a test domain with **15 minute** interval
3. Check debug logs immediately - you should see:
   - "Attempting to schedule alarm"
   - "Alarm permission verified" (status: Granted)
   - "Alarm scheduled successfully"
   - "Alarm scheduled - next expected trigger"

### 3. Wait for First Alarm
1. Wait 15-20 minutes
2. Check debug logs again
3. You should now see:
   - "Background alarm triggered" (this is the key message!)
   - "Flutter binding: Initialized"
   - "Storage service: Initialized"
   - "Debug log service: Initialized"
   - "Notification service: Initialized"
   - "Starting domain check cycle"
   - "Domain check completed: [your-domain]"
   - "Background alarm completed successfully"

### 4. Run Diagnostics
1. Go to Debug Logs screen
2. Tap the **diagnostics icon** (🏥) in the top right
3. Verify:
   - "Alarm manager is initialized" ✓
   - "Alarm permission is granted" ✓
   - "Notification permission is granted" ✓

## If You Still Have Issues

If alarms still aren't firing after verifying all permissions:

### 1. Check Battery Optimization (CRITICAL)
Even with permissions granted, aggressive battery optimization can prevent alarms:
1. Go to **Settings** → **Battery** → **Battery optimization**
2. Find **DomainPulse**
3. Select **Don't optimize** or **No restrictions**

### 2. Check Background Restrictions
1. Go to **Settings** → **Apps** → **DomainPulse** → **Battery**
2. Select **No restrictions** or **Unrestricted**

### 3. Manufacturer-Specific Settings
Some manufacturers have additional restrictions. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed manufacturer-specific instructions:
- Samsung
- Xiaomi/MIUI
- Huawei/EMUI
- OnePlus/OxygenOS
- Oppo/ColorOS
- Vivo/FuntouchOS

### 4. Debug Logs Are Empty
If debug logs remain empty after adding a domain:
1. Check if you see the "Attempting to schedule alarm" log entry
2. If not, there's an issue with the app initialization
3. Try:
   - Force stop the app
   - Clear app cache (Settings → Apps → DomainPulse → Storage → Clear cache)
   - Restart the app
   - Add a domain again

If you see "Attempting to schedule alarm" but no "Background alarm triggered" after 15+ minutes:
1. Check battery optimization (see above)
2. Check alarm permission in Settings → Apps → DomainPulse → Special app access → Alarms & reminders
3. Try a longer interval (1 hour) as some devices defer 15-minute alarms

## Technical Details

### USE_EXACT_ALARM vs SCHEDULE_EXACT_ALARM
- **SCHEDULE_EXACT_ALARM**: Requires user to manually grant permission in settings (Android 12+)
- **USE_EXACT_ALARM**: Automatically granted for non-clock apps, no user action needed (Android 14+)
- The app now declares both to support all Android versions

### Why FOREGROUND_SERVICE?
Android 14+ requires this permission for certain background operations to ensure reliable execution. While our app doesn't run a foreground service, declaring this permission helps with background alarm reliability.

### Enhanced Logging
The alarm callback now logs at every step:
1. Callback triggered
2. Flutter binding initialized
3. Notification service initialized
4. Log entry added
5. Domain checks started
6. Domain checks completed
7. Callback completed

This makes it easy to identify where things might be failing.

### v1.1.2 Critical Fix: Top-Level Callback Function
**The most critical fix**: The alarm callback was moved from a static method to a top-level function. This is a requirement of the `android_alarm_manager_plus` package for the callback to be accessible from the background isolate where alarms execute.

**Before (broken)**:
```dart
class AlarmService {
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    // Callback code
  }
}
```

**After (working)**:
```dart
@pragma('vm:entry-point')
Future<void> alarmCallback() async {
  // Callback code (same as before, just at top level)
}

class AlarmService {
  // scheduleAlarm now references alarmCallback instead of _alarmCallback
}
```

This change is **critical** because without it, the Android alarm manager cannot find and invoke the callback function from the background isolate, resulting in:
- No alarms firing
- No background domain checks
- No notifications
- Empty debug logs (no "Background alarm triggered" messages)

### v1.1.3 Critical Fix: Background Permission Request
**Another critical fix**: The notification service was trying to request permissions during background alarm execution. Permission requests require an Android Activity context to show the permission dialog, but background alarm callbacks run in an isolate without any Activity context.

**The Problem**:
```dart
// In NotificationService.initialize()
await requestNotificationPermission();  // ❌ Crashes in background!

// requestNotificationPermission() calls:
await Permission.notification.request();  // Requires Activity context
```

This caused the error:
```
PlatformException(PermissionHandler.PermissionManager, Unable to detect current Android Activity., null, null)
```

**The Solution**:
```dart
// Add parameter to detect background context
static Future<void> initialize({bool isBackgroundContext = false}) async {
  // ... initialization code ...
  
  if (!isBackgroundContext) {
    // Foreground: Request permission (shows dialog)
    await requestNotificationPermission();
  } else {
    // Background: Only check permission (no dialog)
    final hasPermission = await checkNotificationPermission();
  }
}

// In alarmCallback (background):
await NotificationService.initialize(isBackgroundContext: true);  // ✅ No crash

// In main.dart (foreground):
await NotificationService.initialize();  // ✅ Requests permission normally
```

**Why this works**:
1. **Foreground initialization** (app startup): Calls `initialize()` with default `isBackgroundContext=false`, which requests permission normally with UI dialog
2. **Background initialization** (alarm callback): Calls `initialize(isBackgroundContext: true)`, which only checks permission status without showing dialog
3. **Permission must be granted during foreground**: Users grant permission during normal app usage, then background checks can use those permissions

This change is **critical** because without it:
- Background alarms crash with "Unable to detect current Android Activity" error
- Debug logs show "Background alarm failed" with permission handler errors
- No domain checks execute in background
- No notifications are sent

## Compatibility

This fix maintains backward compatibility:
- **Android 11 and below**: No changes needed, works as before
- **Android 12-13**: Uses SCHEDULE_EXACT_ALARM (user must grant permission)
- **Android 14-15**: Uses USE_EXACT_ALARM (automatically granted) + FOREGROUND_SERVICE

## Related Issues

This fix addresses:
- Empty debug logs on Android 15
- Alarms not triggering on Android 14/15 (and all versions)
- Notifications not showing on Android 14/15
- Missing permission errors on Android 12+
- **v1.1.2**: Background alarms not firing due to callback not being accessible from background isolate
- **v1.1.2**: "Still no checking or notifications triggered" issue
- **v1.1.3**: "Background alarm failed" with "Unable to detect current Android Activity" error
- **v1.1.3**: PlatformException in PermissionHandler during background execution
- **v1.1.3**: Background alarm crashes when trying to request notification permission

For other alarm-related issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
