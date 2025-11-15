# DomainPulse Features Documentation

## Core Features

### 1. Domain Management
- Add new domains to monitor
- Edit existing domain configurations
- Delete domains from monitoring
- Manual domain check (refresh button)

### 2. Expiry Date Tracking

#### RDAP-Based Detection
- Uses RDAP (Registration Data Access Protocol) for accurate domain expiration data
- Queries RDAP API at rdap.org for authoritative expiration information
- Updates automatically during scheduled checks
- All date/time handling done in UTC for consistency

**Technical Details**: The app uses RDAP, the modern standard for domain registration data, which provides accurate expiration dates directly from domain registries. This is more reliable than HTTP headers or WHOIS parsing.

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
Notifications are sent based on configurable timing per domain:
- **Customizable Thresholds**: Set notification timing from 30 minutes to 30 days before expiry
- **Pre-expiry Alerts**: Get notified with days, hours, or minutes remaining
- **Post-expiry Alerts**: Get notified with time elapsed since expiration

Alert messages include:
- Domain name
- Time remaining until expiry (e.g., "expires in 7 days")
- Time elapsed since expiry (e.g., "expired 2 hours ago")
- Clear, human-readable time formatting

### 5. Easy App Installation

The home screen includes a Play Store button:

#### Install Ntfy from Play Store
- One-tap access to install the ntfy.sh app from Google Play Store
- Opens the ntfy.sh app page directly: `https://play.google.com/store/apps/details?id=io.heckel.ntfy`
- Required for receiving push notifications on your device
- Uses `url_launcher` package for seamless external app opening

## Technical Implementation

### Minimal Dependencies
- `flutter` - Flutter SDK
- `http` (^1.1.0) - HTTP requests for domain checks and notifications
- `android_alarm_manager_plus` (^4.0.0) - Background alarm scheduling
- `path_provider` (^2.1.1) - Proper Android storage access
- `url_launcher` (^6.2.0) - Opening Play Store links

### Data Storage
- Local file-based storage using JSON
- Stored in application documents directory (via path_provider)
- Two files:
  - `domains.json` - Domain list with configurations and persistent alarm IDs
  - `settings.json` - App settings (ntfy.sh topic, next alarm ID counter)

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
   - Choose check interval (15m, 1h, 6h, 1d, or custom)
   - Set notification timing (30m, 1h, 6h, 12h, 1d, 7d, or 30d before expiry)
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

1. **RDAP Coverage**: While RDAP is widely supported, some legacy or specialized TLDs may not be available via rdap.org
2. **Android Only**: Currently supports only Android platform.
3. **Storage**: Local storage only, no cloud sync.
4. **Alarms**: Exact alarm behavior may vary by Android version and device manufacturer.

## Future Enhancements

Potential improvements while maintaining minimal dependencies:
- Notification history
- Domain grouping/categories
- Export/import domain list
- Dark theme support
- Multiple RDAP server fallbacks for better coverage
