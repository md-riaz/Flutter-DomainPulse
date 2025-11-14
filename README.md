# DomainPulse

A Flutter Android app for tracking domain expiry dates with alarm-based background checks and push notifications.

## Features

- **Domain Management**: Add, edit, and delete domains to monitor
- **Background Monitoring**: Automatic alarm-based checks at configurable intervals (15m, 1h, 6h, 1d, or custom)
- **Flexible Notifications**: Configurable alert timing per domain (30m, 1h, 6h, 12h, 1d, 7d, or 30d before expiry)
- **Push Notifications**: Alerts via ntfy.sh when domains are approaching expiry or have expired
- **Expiry Tracking**: Parses expiry dates from HTTP headers
- **Easy App Installation**: Direct Play Store link to install ntfy.sh app for receiving push notifications

## Dependencies

This app uses minimal dependencies:
- `flutter` - Flutter SDK
- `http` (^1.1.0) - For domain checking and notifications
- `android_alarm_manager_plus` (^4.0.0) - For background alarm scheduling
- `path_provider` (^2.1.1) - For proper Android storage access
- `url_launcher` (^6.2.0) - For opening Play Store links

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

1. **Install Ntfy App**: Tap "Install Ntfy from Play Store" on the home screen to install the notification app
2. **Configure Notifications**: Go to Settings and enter a unique ntfy.sh topic name
3. **Add Domains**: Tap the + button to add domains to monitor
4. **Set Check Intervals**: Choose from 15m, 1h, 6h, 1d, or set a custom interval
5. **Configure Alert Timing**: Set when to be notified (30m to 30 days before expiry)
6. **Receive Alerts**: Subscribe to your ntfy.sh topic to receive push notifications

## Notifications

This app uses [ntfy.sh](https://ntfy.sh) for push notifications. The app will send alerts based on your configured timing:
- When a domain is approaching expiry (configurable: 30m to 30 days before)
- When a domain has already expired (with time elapsed information)

Subscribe to your topic at: `https://ntfy.sh/your-topic-name`

Install the ntfy.sh app from Play Store using the button on the home screen for best notification delivery.

## License

MIT License
