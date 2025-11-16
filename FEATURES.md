# DomainPulse Features Documentation

## Core Features

### 1. Domain Management
- Add new domains to monitor
- Edit existing domain configurations
- Delete domains from monitoring
- Manual domain check (refresh button)
- Domain availability monitoring
- Debug log page for troubleshooting background checks

### 2. Expiry Date Tracking

#### RDAP-Based Detection
- Uses RDAP (Registration Data Access Protocol) for accurate domain expiration data
- Queries RDAP API at rdap.org for authoritative expiration information
- Updates automatically during scheduled checks
- All date/time handling done in UTC for consistency

**Technical Details**: The app uses RDAP, the modern standard for domain registration data, which provides accurate expiration dates directly from domain registries. This is more reliable than HTTP headers or WHOIS parsing.

### 2.1 Domain Availability Check

#### Real-Time Availability Monitoring
- Checks if a domain is available for registration using RDAP
- Monitors domain status changes (registered → available)
- Visual indicators on the UI showing availability status
- Automatic notifications when a domain becomes available

**Use Case**: This feature is perfect for tracking domains that you want to register. When a domain expires and becomes available for registration, you'll be notified immediately so you can be the first to secure it.

**Technical Details**: 
- Uses RDAP response codes to determine availability
- 404 response = Domain is available for registration
- 200 response = Domain is currently registered
- Status is checked alongside expiry date during background alarms

### 3. Background Monitoring

#### Alarm-Based Checks
- Uses Android Alarm Manager for background scheduling
- Survives app closures and device reboots
- Runs even when device is in sleep mode

#### Configurable Intervals
- 15 minutes
- 1 hour
- 6 hours
- 1 day
- Custom (any number of hours)

Each domain can have its own check interval.

### 4. Local Notifications

#### Native Android Notifications
- Local notifications delivered directly on the device
- No external services or accounts required
- No internet needed for notification delivery

#### Alert Triggers
Notifications are sent based on configurable timing per domain:
- **Customizable Thresholds**: Set notification timing from 30 minutes to 30 days before expiry
- **Pre-expiry Alerts**: Get notified with days, hours, or minutes remaining
- **Post-expiry Alerts**: Get notified with time elapsed since expiration
- **Availability Alerts**: Get notified immediately when a domain becomes available for registration

Alert messages include:
- Domain name
- Time remaining until expiry (e.g., "expires in 7 days")
- Time elapsed since expiry (e.g., "expired 2 hours ago")
- Domain availability status changes
- Clear, human-readable time formatting

## Technical Implementation

### Minimal Dependencies
- `flutter` - Flutter SDK
- `http` (^1.1.0) - HTTP requests for RDAP domain checking
- `android_alarm_manager_plus` (^4.0.0) - Background alarm scheduling
- `path_provider` (^2.1.1) - Proper Android storage access
- `url_launcher` (^6.2.0) - Opening URLs
- `flutter_local_notifications` (^17.0.0) - Local notification delivery

### Data Storage
- Local file-based storage using JSON
- Stored in application documents directory (via path_provider)
- Three files:
  - `domains.json` - Domain list with configurations and persistent alarm IDs
  - `settings.json` - App settings (next alarm ID counter)
  - `debug_logs.json` - Debug logs for troubleshooting (limited to last 500 entries)

### Permissions
Required Android permissions:
- `RECEIVE_BOOT_COMPLETED` - Reschedule alarms after reboot
- `WAKE_LOCK` - Wake device for scheduled checks
- `SCHEDULE_EXACT_ALARM` - Precise alarm timing
- `POST_NOTIFICATIONS` - Show local notifications
- `VIBRATE` - Notification vibration

## User Workflow

1. **Add Domain**
   - Tap + button on home screen
   - Enter domain URL (e.g., example.com)
   - Choose check interval (15m, 1h, 6h, 1d, or custom)
   - Set notification timing (30m, 1h, 6h, 12h, 1d, 7d, or 30d before expiry)
   - Save

2. **Monitor Domains**
   - View all domains on home screen
   - Domains expiring soon shown in red
   - Available domains shown with green checkmark
   - Registered domains shown with blue info badge
   - Manual refresh available per domain
   - Edit or delete as needed

3. **Receive Alerts**
   - Receive local notifications directly on your device
   - Act on expiring domains before it's too late
   - Get notified when domains become available to register them first

4. **Debug Logs** (Troubleshooting)
   - Tap bug report icon in app bar to view debug logs
   - See detailed logs of all background alarm triggers and domain checks
   - Filter logs by level (info, success, error, warning)
   - Clear logs when needed
   - Helpful for diagnosing issues with background checks not firing

5. **Test Notifications** (Optional)
   - Go to Settings
   - Tap "Test Notification" to verify notifications are working

## Limitations

1. **RDAP Coverage**: While RDAP is widely supported, some legacy or specialized TLDs may not be available via rdap.org
2. **Android Only**: Currently supports only Android platform.
3. **Storage**: Local storage only, no cloud sync.
4. **Alarms**: Exact alarm behavior may vary by Android version and device manufacturer.

## Debug Logging

### Purpose
Debug logging helps troubleshoot issues with background domain checks, particularly when alarms may not be firing as expected.

### What Gets Logged
- Background alarm triggers and completions
- Alarm scheduling and cancellation events
- Domain check cycle start and end
- Individual domain check results (success/failure)
- Error details with stack traces when failures occur

### Log Levels
- **Info** (Blue): General information about operations (alarm triggers, domain checks starting)
- **Success** (Green): Successful operations (domain checks completed, alarms scheduled)
- **Warning** (Orange): Non-critical issues that may need attention
- **Error** (Red): Failures that prevent operations from completing

### Log Management
- Automatically limited to last 500 entries to prevent storage bloat
- Filter logs by level for easier debugging
- Clear all logs with confirmation dialog
- Logs persist across app restarts
- Expandable entries to view detailed information

### Access
Tap the bug report icon (🐛) in the home screen app bar to view debug logs.

## Future Enhancements

Potential improvements while maintaining minimal dependencies:
- Notification history
- Domain grouping/categories
- Export/import domain list
- Dark theme support
- Multiple RDAP server fallbacks for better coverage
- Bulk domain availability checker
- Domain price estimation integration
- Export debug logs to file for sharing
