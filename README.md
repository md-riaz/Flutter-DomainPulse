# DomainPulse

A Flutter Android app for tracking domain expiry dates with alarm-based background checks and local notifications.

## Features

- **Domain Management**: Add, edit, and delete domains to monitor
- **Background Monitoring**: Automatic alarm-based checks at configurable intervals (15m, 1h, 6h, 1d, or custom)
- **Flexible Notifications**: Configurable alert timing per domain (30m, 1h, 6h, 12h, 1d, 7d, or 30d before expiry)
- **Local Notifications**: Native Android notifications when domains are approaching expiry or have expired
- **Expiry Tracking**: Uses RDAP (Registration Data Access Protocol) to fetch accurate domain expiration dates
- **Domain Availability Check**: Monitor domain availability status to be the first to register when a domain becomes available
- **Debug Logs**: Comprehensive logging of all background checks and alarms to troubleshoot issues

## Dependencies

This app uses minimal dependencies:
- `flutter` - Flutter SDK
- `http` (^1.1.0) - For RDAP domain checking
- `android_alarm_manager_plus` (^4.0.0) - For background alarm scheduling
- `path_provider` (^2.1.1) - For proper Android storage access
- `url_launcher` (^6.2.0) - For opening URLs
- `flutter_local_notifications` (^17.0.0) - For local notifications

## Setup

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect an Android device or emulator
5. Run `flutter run` to launch the app

## Building APK

To build a release APK:

```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

For GitHub releases, rename the APK to match the version in `pubspec.yaml`:
```bash
mv build/app/outputs/flutter-apk/app-release.apk DomainPulse-v1.0.0.apk
```

## Usage

1. **Add Domains**: Tap the + button to add domains to monitor
2. **Set Check Intervals**: Choose from 15m, 1h, 6h, 1d, or set a custom interval
3. **Configure Alert Timing**: Set when to be notified (30m to 30 days before expiry)
4. **Monitor Availability**: Track domain registration status - see if domains are available for purchase
5. **Receive Alerts**: Get local notifications directly on your device when domains expire or become available
6. **Debug Issues**: Tap the bug report icon to view detailed logs of all background checks
7. **Troubleshoot**: If checks aren't firing, tap the diagnostics icon in debug logs or see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Notifications

This app uses local Android notifications to alert you based on your configured timing:
- When a domain is approaching expiry (configurable: 30m to 30 days before)
- When a domain has already expired (with time elapsed information)
- When a domain becomes available for registration (so you can register it before anyone else)

Notifications are delivered directly to your device without requiring any external services.

## Troubleshooting

If domain checks are not running at the scheduled intervals, see the comprehensive [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide which covers:
- Android version-specific issues (12+, 13+, 14+, 15)
- Battery optimization settings for all major manufacturers
- Common problems and solutions
- Step-by-step diagnosis procedures

Or use the in-app diagnostics: Tap the bug report icon → then the diagnostics (medical kit) icon.

## License

MIT License
