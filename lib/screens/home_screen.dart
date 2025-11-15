import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/domain.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/rdap_service.dart';
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

  Future<void> _deleteDomain(Domain domain) async {
    await AlarmService.cancelAlarm(domain.alarmId);
    await StorageService.deleteDomain(domain.id);
    await _loadDomains();
  }

  Future<void> _checkDomain(Domain domain) async {
    setState(() => _isLoading = true);
    try {
      final expiryDate = await RdapService.getDomainExpiry(domain.url);
      final updatedDomain = domain.copyWith(
        lastChecked: DateTime.now().toUtc(),
        expiryDate: expiryDate,
      );
      await StorageService.updateDomain(updatedDomain);
      await _loadDomains();
      
      if (mounted) {
        if (expiryDate != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Domain checked successfully. Expires: ${_formatDate(expiryDate)}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch expiration date from RDAP'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
          // Install button section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // Opens ntfy.sh app on Play Store for notification handling
                    final playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=io.heckel.ntfy');
                    try {
                      if (await canLaunchUrl(playStoreUrl)) {
                        await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open Play Store'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error opening Play Store: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Install Ntfy from Play Store'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
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
                                  .isBefore(DateTime.now().add(domain.notifyBeforeExpiry));

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
                                  Text(
                                    'Notify: ${_formatInterval(domain.notifyBeforeExpiry)} before expiry',
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
                                    onPressed: () => _deleteDomain(domain),
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
