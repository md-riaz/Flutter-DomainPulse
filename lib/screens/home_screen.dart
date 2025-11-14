import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/domain.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../constants.dart';
import 'domain_form_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Domain> _domains = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    setState(() => _isLoading = true);
    final domains = await StorageService.getDomains();
    setState(() {
      _domains = domains;
      _isLoading = false;
    });
  }

  Future<void> _deleteDomain(String id) async {
    await StorageService.deleteDomain(id);
    await AlarmService.cancelAlarm(id.hashCode);
    await _loadDomains();
  }

  Future<void> _checkDomain(Domain domain) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.head(Uri.parse('https://${domain.url}'));
      final expiry = response.headers['expires'];
      if (expiry != null) {
        final updatedDomain = domain.copyWith(
          lastChecked: DateTime.now(),
          expiryDate: DateTime.tryParse(expiry),
        );
        await StorageService.updateDomain(updatedDomain);
        await _loadDomains();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking domain: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getAppVersion() {
    return kAppVersion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DomainPulse'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Install buttons section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Opens ntfy.sh app on Play Store for notification handling
                          // URL: https://play.google.com/store/apps/details?id=io.heckel.ntfy
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Play Store for ntfy.sh app...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications),
                        label: const Text('Install Ntfy'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final version = _getAppVersion();
                          final apkUrl =
                              'https://github.com/md-riaz/Flutter-DomainPulse/releases/download/v$version/DomainPulse-v$version.apk';
                          // This would open the URL in a real app
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Download: $apkUrl'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('GitHub APK'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Version: ${_getAppVersion()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Domains list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _domains.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.domain_disabled,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No domains added yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text('Tap + to add your first domain'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _domains.length,
                        itemBuilder: (context, index) {
                          final domain = _domains[index];
                          final isExpiringSoon = domain.expiryDate != null &&
                              domain.expiryDate!
                                  .isBefore(DateTime.now().add(const Duration(hours: 1)));

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: isExpiringSoon
                                ? Colors.red.shade50
                                : null,
                            child: ListTile(
                              leading: Icon(
                                isExpiringSoon
                                    ? Icons.warning
                                    : Icons.domain,
                                color: isExpiringSoon
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(domain.url),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (domain.expiryDate != null)
                                    Text(
                                      'Expires: ${_formatDate(domain.expiryDate!)}',
                                      style: TextStyle(
                                        color: isExpiringSoon
                                            ? Colors.red
                                            : null,
                                      ),
                                    ),
                                  if (domain.lastChecked != null)
                                    Text(
                                      'Last checked: ${_formatDate(domain.lastChecked!)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  Text(
                                    'Check interval: ${_formatInterval(domain.checkInterval)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () => _checkDomain(domain),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DomainFormScreen(domain: domain),
                                        ),
                                      );
                                      await _loadDomains();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteDomain(domain.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DomainFormScreen()),
          );
          await _loadDomains();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatInterval(Duration interval) {
    if (interval.inMinutes < 60) {
      return '${interval.inMinutes}m';
    } else if (interval.inHours < 24) {
      return '${interval.inHours}h';
    } else {
      return '${interval.inDays}d';
    }
  }
}
