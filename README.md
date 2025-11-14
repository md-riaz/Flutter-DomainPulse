# DomainPulse

A Flutter Android app for tracking domain expiry dates with alarm-based background checks and push notifications.

## Features

- **Domain Management**: Add, edit, and delete domains to monitor
- **Background Monitoring**: Automatic alarm-based checks at configurable intervals (15m, 1h, 6h, 1d, or custom)
- **Push Notifications**: Alerts via ntfy.sh when domains are expiring soon (1 hour threshold) or have expired
- **Expiry Tracking**: Parses expiry dates from HTTP headers
- **Easy Notifications**: Quick access to install ntfy.sh app for receiving push notifications

## Dependencies

This app uses minimal dependencies:
- `flutter` - Flutter SDK
- `http` (^1.1.0) - For domain checking and notifications
- `android_alarm_manager_plus` (^3.0.4) - For background alarm scheduling

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

1. **Configure Notifications**: Go to Settings and enter a unique ntfy.sh topic name
2. **Add Domains**: Tap the + button to add domains to monitor
3. **Set Check Intervals**: Choose from 15m, 1h, 6h, 1d, or set a custom interval
4. **Receive Alerts**: Subscribe to your ntfy.sh topic to receive push notifications

## Notifications

This app uses [ntfy.sh](https://ntfy.sh) for push notifications. The app will send alerts when:
- A domain expires in less than 1 hour
- A domain has already expired

Subscribe to your topic at: `https://ntfy.sh/your-topic-name`

## License

MIT License
