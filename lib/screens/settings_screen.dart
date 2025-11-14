import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _topicController = TextEditingController();
  String? _currentTopic;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final topic = await StorageService.getNtfyTopic();
    setState(() {
      _currentTopic = topic;
      _topicController.text = topic ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveTopic() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }

    await StorageService.setNtfyTopic(topic);
    setState(() => _currentTopic = topic);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic saved successfully')),
      );
    }
  }

  Future<void> _testNotification() async {
    if (_currentTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save a topic first')),
      );
      return;
    }

    try {
      await NotificationService.sendNotification(
        _currentTopic!,
        'Test Notification',
        'This is a test notification from DomainPulse',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ntfy.sh Notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter a unique topic name for receiving push notifications. '
                          'This is a one-time setup.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            labelText: 'Ntfy.sh Topic',
                            hintText: 'my-unique-topic',
                            prefixIcon: Icon(Icons.notifications),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveTopic,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Save Topic'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _currentTopic != null
                                    ? _testNotification
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Test'),
                              ),
                            ),
                          ],
                        ),
                        if (_currentTopic != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Topic:',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentTopic!,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe at: https://ntfy.sh/$_currentTopic',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
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
                          'About',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'DomainPulse monitors domain expiry dates and sends '
                          'notifications when domains are about to expire or have expired.',
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
                          title: Text('Alert Threshold'),
                          subtitle: Text('Configurable per domain (30m to 30 days before expiry)'),
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
