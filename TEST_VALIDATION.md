# Test Validation Checklist for Android 15 Fix

## Pre-Test Setup
- [ ] Device running Android 15 (API 35) or Android 14 (API 34)
- [ ] Fresh install of the app or cleared app data
- [ ] Device has internet connectivity

## Test 1: Permission Request on Startup
**Goal**: Verify that alarm permission is requested on app startup

### Steps:
1. Install the app (fresh install)
2. Open the app
3. Observe permission prompts

### Expected Results:
- [ ] App opens successfully
- [ ] Either see alarm permission prompt OR permission is automatically granted (Android 14+)
- [ ] No app crashes

### Debug Logs to Check:
- Look for "Alarm permission" messages in system logs or debug output

---

## Test 2: Alarm Scheduling with Permission Verification
**Goal**: Verify that alarms can be scheduled with proper permission checks

### Steps:
1. Open DomainPulse app
2. Tap the + button to add a domain
3. Enter a test domain (e.g., "example.com")
4. Set check interval to "15 minutes"
5. Set notification timing to "30 minutes"
6. Save the domain
7. Immediately tap the bug report icon (🐛)

### Expected Results in Debug Logs:
- [ ] "Attempting to schedule alarm" log entry
- [ ] "Alarm permission verified" with "Permission status: Granted"
- [ ] "Alarm scheduled successfully" log entry
- [ ] "Alarm scheduled - next expected trigger" with timestamp

### If Permission Not Granted:
- [ ] "Alarm permission not granted - attempting to request" warning
- [ ] "Failed to schedule alarm - permission denied" error with detailed instructions
- [ ] Instructions include steps to grant permission manually

---

## Test 3: Alarm Callback Execution
**Goal**: Verify that alarm callback executes after the scheduled interval

### Steps:
1. After adding a domain (from Test 2), note the current time
2. Wait 15-20 minutes (add buffer for system delays)
3. Open the app
4. Tap the bug report icon (🐛)
5. Check debug logs

### Expected Results in Debug Logs (after 15-20 minutes):
- [ ] "Background alarm triggered" - **THIS IS THE CRITICAL MESSAGE**
- [ ] "Flutter binding: Initialized"
- [ ] "Notification service: Initialized"
- [ ] "About to check domains..."
- [ ] "Starting domain check cycle"
- [ ] "Checking domain: example.com"
- [ ] "Domain check completed: example.com"
- [ ] "Background alarm completed successfully"

### If Logs Are Empty or Missing Alarm Trigger:
This indicates one of these issues:
- [ ] Battery optimization is blocking the alarm (need to disable)
- [ ] Alarm permission isn't actually granted (check settings)
- [ ] Background restrictions are enabled (need to disable)

---

## Test 4: Diagnostics Check
**Goal**: Verify that diagnostics show correct permission status

### Steps:
1. Open the app
2. Tap the bug report icon (🐛)
3. Tap the diagnostics icon (🏥 medical kit) in top right
4. Wait for diagnostics to complete
5. Check debug logs

### Expected Results in Debug Logs:
- [ ] "Running alarm diagnostics"
- [ ] "Alarm manager is initialized" (success)
- [ ] "Alarm permission is granted" (success)
- [ ] "Notification permission is granted" (success)
- [ ] "Diagnostics completed"

### If Permissions Not Granted:
- [ ] See error logs with "ACTION REQUIRED" sections
- [ ] Instructions are clear and actionable
- [ ] Can follow instructions to grant permissions

---

## Test 5: Notification Display
**Goal**: Verify that notifications are shown when domain conditions are met

### Steps:
1. Add a domain that will trigger a notification soon
   - Option A: Use a domain expiring soon
   - Option B: Wait for the alarm to fire (15 minutes)
2. Wait for alarm to fire
3. Check notification drawer

### Expected Results:
- [ ] Notification appears in notification drawer
- [ ] Notification has proper title and message
- [ ] Notification is dismissible
- [ ] Tapping notification opens the app (if implemented)

### If No Notification:
- [ ] Check debug logs for "Local notification sent" message
- [ ] Verify notification permission is granted
- [ ] Check Do Not Disturb settings on device

---

## Test 6: Battery Optimization Warning
**Goal**: Verify that battery optimization can be detected and warned about

### Steps:
1. Go to device Settings → Battery → Battery optimization
2. Find DomainPulse
3. Enable battery optimization (optimize)
4. Open DomainPulse app
5. Add a domain with 15-minute interval
6. Wait 20-30 minutes
7. Check debug logs

### Expected Results:
- [ ] If battery optimization prevents alarm, it should be noted in system behavior
- [ ] User should see guidance in TROUBLESHOOTING.md
- [ ] ANDROID_15_FIX.md provides clear instructions

---

## Test 7: Multiple Alarms
**Goal**: Verify that multiple domains can be scheduled with different intervals

### Steps:
1. Add domain 1 with 15-minute interval
2. Add domain 2 with 1-hour interval
3. Add domain 3 with 6-hour interval
4. Check debug logs immediately

### Expected Results:
- [ ] All three "Attempting to schedule alarm" logs
- [ ] All three "Alarm permission verified" logs
- [ ] All three "Alarm scheduled successfully" logs
- [ ] Each shows different "next expected trigger" time

### After Waiting:
- [ ] 15-minute alarm fires first
- [ ] 1-hour alarm fires at expected time
- [ ] All alarms continue firing at their intervals

---

## Test 8: App Restart
**Goal**: Verify that alarms persist after app restart

### Steps:
1. Add a domain with 15-minute interval
2. Force stop the app (Settings → Apps → DomainPulse → Force stop)
3. Wait 20 minutes without opening the app
4. Open the app
5. Check debug logs

### Expected Results:
- [ ] "Background alarm triggered" log exists (alarm fired while app was closed)
- [ ] Domain was checked during background alarm
- [ ] App works normally after restart

---

## Test 9: Device Reboot
**Goal**: Verify that alarms are rescheduled after device reboot

### Steps:
1. Add a domain with 15-minute interval
2. Verify alarm scheduled successfully in debug logs
3. Reboot the device
4. Wait 20 minutes after reboot
5. Open DomainPulse app
6. Check debug logs

### Expected Results:
- [ ] "Background alarm triggered" log exists after reboot
- [ ] Alarms were rescheduled automatically
- [ ] Domain checks continue working

---

## Test 10: Permission Revocation
**Goal**: Verify app handles permission revocation gracefully

### Steps:
1. Add a domain successfully
2. Go to Settings → Apps → DomainPulse → Special app access → Alarms & reminders
3. Disable the permission
4. Try to add another domain
5. Check debug logs

### Expected Results:
- [ ] "Alarm permission not granted - attempting to request" warning
- [ ] "Failed to schedule alarm - permission denied" error
- [ ] Clear instructions on how to re-grant permission
- [ ] App doesn't crash

---

## Android 15 Specific Tests

### Test A15-1: USE_EXACT_ALARM Permission
**Verify Android 14+ permission is used**

### Steps:
1. Check AndroidManifest.xml
2. Verify USE_EXACT_ALARM permission is declared

### Expected Results:
- [ ] `<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>` present
- [ ] Comment explains it's for Android 14+

### Test A15-2: FOREGROUND_SERVICE Permission
**Verify foreground service permission is declared**

### Steps:
1. Check AndroidManifest.xml
2. Verify FOREGROUND_SERVICE permission is declared

### Expected Results:
- [ ] `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>` present
- [ ] Comment explains it's required for Android 14+

---

## Validation Summary

### Critical Success Criteria:
- [ ] All permissions are granted on Android 15
- [ ] Alarms fire after scheduled interval
- [ ] Debug logs show "Background alarm triggered"
- [ ] Notifications appear when expected
- [ ] App works after restart and reboot
- [ ] Permission errors have clear, actionable messages

### Documentation Validation:
- [ ] ANDROID_15_FIX.md has accurate verification steps
- [ ] TROUBLESHOOTING.md covers Android 15 issues
- [ ] FEATURES.md lists all new permissions
- [ ] README.md mentions Android 15 support

### Known Acceptable Limitations:
- [ ] Some manufacturers may still defer alarms (documented)
- [ ] Battery optimization can still block alarms (documented)
- [ ] Shorter intervals (<15 min) may be deferred (documented)

---

## Reporting Issues

If any test fails, please report:
1. Device model and Android version
2. Which test failed
3. Expected vs actual results
4. Debug logs (screenshot or text)
5. Screenshots of permission settings

---

## Success Criteria for Release

All of the following must pass:
- [ ] Tests 1-4 pass (critical functionality)
- [ ] Test 5 passes (notifications work)
- [ ] Test 7 passes (multiple domains)
- [ ] Test 8 passes (app restart)
- [ ] Test 9 passes (device reboot)
- [ ] Android 15 specific tests pass
- [ ] No crashes or errors
- [ ] Documentation is accurate

If Tests 6 or 10 show issues, they should be documented in TROUBLESHOOTING.md but don't block release.
