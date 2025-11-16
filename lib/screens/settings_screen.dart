import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/alarm_permission_service.dart';
import '../constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _alarmPermissionStatus = 'Checking...';
  bool _alarmPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAlarmPermission();
  }

  Future<void> _checkAlarmPermission() async {
    final granted = await AlarmPermissionService.checkAlarmPermission();
    final message = await AlarmPermissionService.getPermissionStatusMessage();
    setState(() {
      _alarmPermissionGranted = granted;
      _alarmPermissionStatus = message;
    });
  }

  Future<void> _requestAlarmPermission() async {
    final granted = await AlarmPermissionService.requestAlarmPermission();
    
    // Refresh the permission status
    await _checkAlarmPermission();
    
    if (mounted) {
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm permission granted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm permission not granted. Please enable it in system settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _openAlarmSettings() async {
    final opened = await AlarmPermissionService.openAlarmSettings();
    
    if (mounted) {
      if (opened) {
        // Wait a bit for user to return from settings
        await Future.delayed(const Duration(seconds: 1));
        // Refresh the permission status
        await _checkAlarmPermission();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open settings. Please check manually.'),
          ),
        );
      }
    }
  }
  Future<void> _testNotification() async {
    try {
      // Check permission first
      final hasPermission = await NotificationService.checkNotificationPermission();
      
      if (!hasPermission) {
        // Request permission
        final granted = await NotificationService.requestNotificationPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permission denied. Please enable it in settings.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }
      
      final success = await NotificationService.sendNotification(
        'Test Notification',
        'This is a test notification from DomainPulse',
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test notification sent successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send notification. Check permissions.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alarm Permission',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _alarmPermissionGranted ? Icons.check_circle : Icons.warning,
                        color: _alarmPermissionGranted ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _alarmPermissionStatus,
                          style: TextStyle(
                            color: _alarmPermissionGranted ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_alarmPermissionGranted) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Background domain checks require alarm permission on Android 12+. '
                      'Grant this permission to enable automatic monitoring.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _requestAlarmPermission,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Request Permission'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openAlarmSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Settings'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DomainPulse sends local notifications directly on this device:\n'
                    '• Expiry alerts: Based on your configured timing (before/after expiration)\n'
                    '• Availability alerts: Immediately when a domain becomes available',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _testNotification,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Test Notification'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DomainPulse monitors domain expiry dates and availability status. '
                    'Choose monitoring mode per domain: expiry only, availability only, or both.',
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text(kAppVersion),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const ListTile(
                    leading: Icon(Icons.schedule),
                    title: Text('Check Intervals'),
                    subtitle: Text('15m, 1h, 6h, 1d, or custom'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const ListTile(
                    leading: Icon(Icons.notifications_active),
                    title: Text('Notification Settings'),
                    subtitle: Text('Expiry: Configurable per domain (30m to 30 days before/after)\nAvailability: Immediate alerts'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
