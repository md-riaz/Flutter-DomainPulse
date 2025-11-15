import 'package:flutter/material.dart';
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
      DateTime? expiryDate;
      bool? isAvailable;
      
      // Check expiry if monitoring expiry
      if (domain.monitoringMode == MonitoringMode.expiryOnly || 
          domain.monitoringMode == MonitoringMode.both) {
        expiryDate = await RdapService.getDomainExpiry(domain.url);
      }
      
      // Check availability if monitoring availability
      if (domain.monitoringMode == MonitoringMode.availabilityOnly || 
          domain.monitoringMode == MonitoringMode.both) {
        isAvailable = await RdapService.isDomainAvailable(domain.url);
      }
      
      final updatedDomain = domain.copyWith(
        lastChecked: DateTime.now().toUtc(),
        expiryDate: expiryDate ?? domain.expiryDate,
        isAvailable: isAvailable ?? domain.isAvailable,
        lastAvailabilityCheck: isAvailable != null ? DateTime.now().toUtc() : domain.lastAvailabilityCheck,
      );
      await StorageService.updateDomain(updatedDomain);
      await _loadDomains();
      
      if (mounted) {
        String message = '';
        
        if (domain.monitoringMode == MonitoringMode.expiryOnly || 
            domain.monitoringMode == MonitoringMode.both) {
          if (expiryDate != null) {
            message = 'Expires: ${_formatDate(expiryDate)}';
          } else {
            message = 'Could not fetch expiration date';
          }
        }
        
        if (domain.monitoringMode == MonitoringMode.availabilityOnly || 
            domain.monitoringMode == MonitoringMode.both) {
          if (isAvailable == true) {
            if (message.isNotEmpty) message += '\n';
            message += '✓ Domain is AVAILABLE for registration';
          } else if (isAvailable == false) {
            if (message.isNotEmpty) message += '\n';
            message += '✗ Domain is registered';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isAvailable == true ? Colors.green : (expiryDate != null ? Colors.green : Colors.orange),
          ),
        );
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
          // App version section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.domain, size: 20),
                const SizedBox(width: 8),
                Text(
                  'DomainPulse - Version: ${_getAppVersion()}',
                  style: Theme.of(context).textTheme.titleMedium,
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
                          // Only check expiry warnings for domains monitoring expiry
                          final isExpiringSoon = (domain.monitoringMode == MonitoringMode.expiryOnly || 
                              domain.monitoringMode == MonitoringMode.both) &&
                              domain.expiryDate != null &&
                              domain.expiryDate!
                                  .isBefore(DateTime.now().toUtc().add(domain.notifyBeforeExpiry));

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
                                  // Show availability status only for domains monitoring availability
                                  if ((domain.monitoringMode == MonitoringMode.availabilityOnly || 
                                      domain.monitoringMode == MonitoringMode.both) && 
                                      domain.isAvailable == true)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AVAILABLE for registration',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if ((domain.monitoringMode == MonitoringMode.availabilityOnly || 
                                      domain.monitoringMode == MonitoringMode.both) && 
                                      domain.isAvailable == false)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Registered',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  // Show expiry date only for domains monitoring expiry
                                  if ((domain.monitoringMode == MonitoringMode.expiryOnly || 
                                      domain.monitoringMode == MonitoringMode.both) && 
                                      domain.expiryDate != null)
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
                                    'Mode: ${_formatMonitoringMode(domain.monitoringMode)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Check interval: ${_formatInterval(domain.checkInterval)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Notify: ${_formatNotificationTiming(domain.notifyBeforeExpiry)}',
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
    // Convert UTC to local time
    final localDate = date.toLocal();
    return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} '
        '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
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

  String _formatNotificationTiming(Duration interval) {
    if (interval == Duration.zero) {
      return 'after expiry';
    } else if (interval.inMinutes < 60) {
      return '${interval.inMinutes}m before expiry';
    } else if (interval.inHours < 24) {
      return '${interval.inHours}h before expiry';
    } else {
      return '${interval.inDays}d before expiry';
    }
  }

  String _formatMonitoringMode(MonitoringMode mode) {
    switch (mode) {
      case MonitoringMode.expiryOnly:
        return 'Expiry only';
      case MonitoringMode.availabilityOnly:
        return 'Availability only';
      case MonitoringMode.both:
        return 'Expiry + Availability';
    }
  }
}
