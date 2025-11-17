# DomainPulse Troubleshooting Guide

## Recent Fixes

### v1.1.4 - One-Shot Alarms for Reliable Background Checks

**If domain checks are still not running accurately when the app is closed**, this has been fixed in v1.1.4. The root cause was that periodic alarms with exact timing are heavily restricted by Android's Doze mode and are often batched or deferred when the app is in the background.

**What was fixed:**
- ✅ Replaced periodic alarms with one-shot alarms (much more reliable in Doze mode)
- ✅ Implemented self-rescheduling after each check cycle
- ✅ One-shot alarms have higher priority in Android's scheduler
- ✅ No more batching or deferral of alarms when app is closed
- ✅ Each domain check fires at its exact scheduled time

**Why this matters:**
Android treats one-shot alarms with `exact: true` and `allowWhileIdle: true` with much higher priority than periodic alarms. This is the recommended approach for reliable background work when the app is not running.

### v1.1.3 - Background Alarm Permission Error Fix

**If you're seeing "Background alarm failed" errors with "Unable to detect current Android Activity"**, this has been fixed. The root cause was that the notification service was trying to request permissions during background alarm execution, which requires a UI context that doesn't exist in the background.

**What was fixed:**
- ✅ Notification permission requests are now skipped in background contexts
- ✅ Background alarm callbacks only check permission status (no dialog)
- ✅ Permission requests only happen during foreground app usage
- ✅ Background domain checks and notifications work properly

### v1.1.2 - Top-Level Callback Function Fix

**If you're experiencing issues with alarms and notifications not triggering**, this was fixed in v1.1.2. The root cause was that the alarm callback function was implemented as a static method instead of a top-level function, which prevented the Android alarm manager from properly invoking it in the background isolate.

**What was fixed:**
- ✅ Alarm callback is now a top-level function (required by `android_alarm_manager_plus`)
- ✅ Background domain checks will now execute properly at scheduled intervals
- ✅ Notifications will be sent when domains approach expiry or become available
- ✅ Better error logging when notifications fail (e.g., missing permissions)

### If you still have issues after updating:
Make sure to check the sections below, especially the permission and battery optimization settings.

## Domain Checks Not Firing

If your domain checks are not running at the scheduled intervals, follow these steps:

### 1. Check Debug Logs

1. Tap the **bug report icon** (🐛) in the home screen
2. Look for these log entries:
   - "Alarm scheduled for domain: X" (should appear when you add/edit a domain)
   - "Background alarm triggered" (should appear at each interval)
   - "Domain check cycle completed" (should appear after checks run)

If you don't see "Background alarm triggered" entries:
- The alarms are not firing properly
- Continue to steps below

### 2. Android Version-Specific Issues

#### Android 15 (API 35)
Android 15 has the strictest requirements for background work and exact alarms:

1. **Alarm Permission**: Open **Settings** → **Apps** → **DomainPulse** → **Special app access** → **Alarms & reminders** and enable it
2. **Notification Permission**: Go to **Settings** → **Apps** → **DomainPulse** → **Permissions** → **Notifications** and enable it
3. **Battery Optimization**: Go to **Settings** → **Battery** → **Battery optimization** → Find DomainPulse → Select **Don't optimize**
4. **Background Restrictions**: Go to **Settings** → **Apps** → **DomainPulse** → **Battery** → Select **No restrictions** or **Unrestricted**

**Critical for Android 15**: The app will now verify alarm permissions before scheduling. If you see permission warnings in debug logs, follow the instructions provided. Android 15 also requires USE_ALARM_ATTRIBUTES permission, which is automatically granted through the manifest.

#### Android 14 (API 34)
Android 14 introduced USE_EXACT_ALARM permission:

1. Open **Settings** on your device
2. Go to **Apps** → **DomainPulse**
3. Tap **Permissions** or **Special app access**
4. Look for **Alarms & reminders** or **Schedule exact alarms**
5. Enable this permission
6. Disable battery optimization (see Android 15 instructions above)

**Why?** Android 14+ uses USE_EXACT_ALARM as an alternative to SCHEDULE_EXACT_ALARM. The app now supports both. Android 15+ also requires USE_ALARM_ATTRIBUTES for alarm scheduling attributes.

#### Android 12-13 (API 31-33)
Android 12 and 13 require explicit permission for exact alarms:

1. Open **Settings** on your device
2. Go to **Apps** → **DomainPulse**
3. Tap **Permissions** or **Special app access**
4. Look for **Alarms & reminders** or **Schedule exact alarms**
5. Enable this permission

**Why?** Android 12+ restricts exact alarm scheduling for security/battery reasons. Apps must request this permission explicitly.

#### Android 13+ (API 33+)
Additional notification permission is required:

1. When you first add a domain, you should see a notification permission prompt
2. If you denied it, go to **Settings** → **Apps** → **DomainPulse** → **Permissions** → **Notifications**
3. Enable notifications

### 3. Battery Optimization

Many devices aggressively kill background processes to save battery. This is the **most common reason** alarms don't fire.

#### General Steps (All Android):
1. Open **Settings**
2. Go to **Battery** → **Battery optimization** or **App power management**
3. Find **DomainPulse**
4. Select **Don't optimize** or **No restrictions**

#### Manufacturer-Specific Settings:

##### Samsung:
1. **Settings** → **Apps** → **DomainPulse**
2. Tap **Battery**
3. Turn off **Optimize battery usage**
4. Enable **Background activity**
5. Go to **Settings** → **Device care** → **Battery** → **App power management**
6. Add DomainPulse to **Apps that won't be put to sleep**

##### Xiaomi/MIUI:
1. **Settings** → **Apps** → **Manage apps** → **DomainPulse**
2. Enable **Autostart**
3. Tap **Battery saver**
4. Select **No restrictions**
5. Go to **Settings** → **Battery & performance** → **App battery saver**
6. Turn off battery saver for DomainPulse

##### Huawei/EMUI:
1. **Settings** → **Apps** → **DomainPulse**
2. Tap **Battery**
3. Select **Manual** under **Launch**
4. Enable all options (Auto-launch, Secondary launch, Run in background)
5. Go to **Settings** → **Battery** → **App launch**
6. Set DomainPulse to **Manage manually**

##### OnePlus/OxygenOS:
1. **Settings** → **Battery** → **Battery optimization**
2. Tap **DomainPulse**
3. Select **Don't optimize**
4. Go to **Settings** → **Apps** → **DomainPulse** → **Battery**
5. Enable **Background activity**

##### Oppo/ColorOS:
1. **Settings** → **Battery** → **App Freeze**
2. Disable for DomainPulse
3. **Settings** → **Battery** → **Power monitor**
4. Find DomainPulse and disable monitoring

##### Vivo/FuntouchOS:
1. **Settings** → **Battery** → **Background power consumption management**
2. Find DomainPulse
3. Turn off background restrictions

### 4. Check Interval Settings

#### Minimum Recommended Interval: 15 minutes

Android may defer or batch alarms shorter than 15 minutes to save battery. If you're using very short intervals:

1. Try increasing to at least **15 minutes** or **1 hour**
2. Check debug logs to see actual firing times
3. Some devices may still defer 15-minute alarms to 30 minutes

#### Testing:
1. Set a domain to check every **1 hour**
2. Add it and note the time
3. Check debug logs after 1 hour to see if alarm fired
4. If it works, the issue was likely interval-related

### 5. Verify Alarm Scheduling

#### Check that alarms are being scheduled:

1. Add a new domain
2. Immediately check debug logs (bug report icon)
3. You should see:
   ```
   ✅ "Attempting to schedule alarm"
   ✅ "Alarm scheduled successfully"
   ✅ "Alarm scheduled - next expected trigger"
   ```

If you see ❌ "Failed to schedule alarm":
- Check the error details in the log
- The issue is with alarm scheduling, not firing
- Contact support with error details

### 6. Device-Specific Quirks

#### Doze Mode (All Android 6+):
Android's Doze mode restricts background activity when device is idle:

- Alarms should still fire (they're exempt from Doze)
- But if combined with manufacturer restrictions, they may not
- Solution: Disable battery optimization (see step 3)

#### App Standby:
Android puts rarely-used apps into standby:

- Open DomainPulse regularly to prevent standby
- Or disable battery optimization

### 7. Verify with Diagnostics

1. Go to **Debug Logs** (bug report icon)
2. Tap **Diagnostics** icon (medical kit) in the top right
3. Review the diagnostic information
4. Follow the troubleshooting steps listed there

### 8. Testing Your Setup

#### Quick Test:
1. Clear debug logs (in Debug Logs screen)
2. Add a test domain with **15 minute** interval
3. Wait 20 minutes
4. Check debug logs
5. You should see:
   - Alarm scheduled entries (immediately)
   - Background alarm triggered (after ~15 min)
   - Domain check entries (after ~15 min)

#### Expected Log Sequence:
```
INFO: Attempting to schedule alarm
SUCCESS: Alarm scheduled successfully
INFO: Alarm scheduled - next expected trigger
... wait for interval ...
INFO: Background alarm triggered
INFO: Starting domain check cycle
INFO: Checking domain: example.com
SUCCESS: Domain check completed: example.com
SUCCESS: Domain check cycle completed
SUCCESS: Background alarm completed successfully
```

### 9. Still Not Working?

If you've tried all the above and alarms still don't fire:

1. **Reboot your device** - This can resolve permission/system issues
2. **Reinstall the app** - This resets all permissions and settings
3. **Try a different device** - To rule out device-specific issues
4. **Check Android version** - Very old or heavily modified Android may have issues
5. **Export debug logs** - Share them when seeking help

### 10. Known Limitations

#### Cannot Be Fixed:
- Some manufacturers have **extremely aggressive** battery management that cannot be fully disabled
- Custom ROMs may have additional restrictions
- Some devices will still defer alarms despite all settings

#### Workarounds:
- Use longer intervals (6 hours or 1 day)
- Keep the app open in background
- Use manual refresh button regularly
- Contact your device manufacturer about their battery restrictions

## Common Error Messages

### "Could not fetch domain expiration date via RDAP"
- Domain may not be registered yet
- Domain TLD not supported by RDAP
- Network connectivity issue
- Solution: Check domain spelling, try manual refresh

### "Failed to schedule alarm"
- Permission issue (see Android 12+ section)
- System error
- Solution: Check debug logs for details, restart app

### "Error checking domain"
- Network error
- RDAP server issue
- Invalid domain format
- Solution: Check internet connection, verify domain format

## Getting Help

When seeking help, please provide:

1. **Device model and Android version**
2. **App version** (shown on home screen)
3. **Debug logs** (screenshot or copy text)
4. **Steps you've already tried** from this guide
5. **Check interval** you're using
6. **Exact error messages** if any

## Prevention Tips

1. **Don't use very short intervals** (< 15 minutes)
2. **Disable battery optimization** immediately after install
3. **Open app regularly** to prevent standby
4. **Check debug logs** after adding first domain to verify it works
5. **Keep notifications enabled** so you know when checks run

## Additional Resources

- Android battery optimization: https://dontkillmyapp.com/
- Manufacturer-specific guides: https://dontkillmyapp.com/ (select your device)
- RDAP information: https://about.rdap.org/
