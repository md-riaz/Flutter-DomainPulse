# DomainPulse Features Documentation

## Core Features

### 1. Domain Management
- Add new domains to monitor
- Edit existing domain configurations
- Delete domains from monitoring
- Manual domain check (refresh button)

### 2. Expiry Date Tracking

DomainPulse supports two methods for tracking domain expiry dates:

#### Manual Entry
- Users can manually enter the expiry date when adding/editing a domain
- Format: YYYY-MM-DD
- Includes a date picker for easy selection
- Ideal when you know the exact expiry date from your registrar

#### Automatic Detection (Limited)
- Attempts to parse expiry information from HTTP headers
- Preserves manually entered dates if automatic detection fails
- Updates automatically during scheduled checks

**Note**: Due to minimal dependency requirements, full WHOIS or SSL certificate checking is not implemented. For most accurate tracking, we recommend manually entering expiry dates from your domain registrar.

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

### 4. Push Notifications

#### Ntfy.sh Integration
- One-time topic setup in Settings
- No account or authentication required
- Subscribe to your topic at: https://ntfy.sh/your-topic-name

#### Alert Triggers
Notifications are sent when:
- Domain expires in less than 1 hour
- Domain has already expired

Alert messages include:
- Domain name
- Time remaining (if not yet expired)
- Clear indication if already expired

### 5. Installation Options

The home screen includes two installation buttons:

#### Play Store Button
- Ready for when app is published to Google Play Store
- Currently shows a placeholder message

#### GitHub Releases APK
- Downloads APK from GitHub Releases
- URL format: `https://github.com/md-riaz/Flutter-DomainPulse/releases/download/v{VERSION}/DomainPulse-v{VERSION}.apk`
- Version is automatically read from pubspec.yaml (currently 1.0.0)

## Technical Implementation

### Minimal Dependencies
- `flutter` - Flutter SDK
- `http` (^1.1.0) - HTTP requests for domain checks and notifications
- `android_alarm_manager_plus` (^3.0.4) - Background alarm scheduling

### Data Storage
- Local file-based storage using JSON
- Stored in `/tmp/domainpulse/` directory
- Two files:
  - `domains.json` - Domain list with configurations
  - `settings.json` - App settings (ntfy.sh topic)

### Permissions
Required Android permissions:
- `INTERNET` - For domain checks and notifications
- `RECEIVE_BOOT_COMPLETED` - Reschedule alarms after reboot
- `WAKE_LOCK` - Wake device for scheduled checks
- `SCHEDULE_EXACT_ALARM` - Precise alarm timing

## User Workflow

1. **Initial Setup**
   - Open Settings
   - Enter a unique ntfy.sh topic name
   - Test notification to verify setup

2. **Add Domain**
   - Tap + button on home screen
   - Enter domain URL (e.g., example.com)
   - Optionally set expiry date
   - Choose check interval
   - Save

3. **Monitor Domains**
   - View all domains on home screen
   - Domains expiring soon shown in red
   - Manual refresh available per domain
   - Edit or delete as needed

4. **Receive Alerts**
   - Subscribe to your ntfy.sh topic
   - Receive push notifications
   - Act on expiring domains before it's too late

## Limitations

1. **Expiry Detection**: HTTP header-based detection is limited. Manual entry recommended.
2. **Android Only**: Currently supports only Android platform.
3. **Storage**: Local storage only, no cloud sync.
4. **Alarms**: Exact alarm behavior may vary by Android version and device manufacturer.

## Future Enhancements

Potential improvements while maintaining minimal dependencies:
- Better HTTP header parsing (Date, Last-Modified, etc.)
- Notification history
- Domain grouping/categories
- Export/import domain list
- Dark theme support
