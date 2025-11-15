import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/rdap_service.dart';

class DomainFormScreen extends StatefulWidget {
  final Domain? domain;

  const DomainFormScreen({super.key, this.domain});

  @override
  State<DomainFormScreen> createState() => _DomainFormScreenState();
}

class _DomainFormScreenState extends State<DomainFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  Duration _selectedInterval = const Duration(hours: 1);
  Duration _notifyBeforeExpiry = Duration.zero; // Default to after expiration
  MonitoringMode _monitoringMode = MonitoringMode.both;
  bool _isSaving = false;

  final List<Duration> _intervalOptions = [
    const Duration(minutes: 15),
    const Duration(hours: 1),
    const Duration(hours: 6),
    const Duration(days: 1),
  ];

  final List<Duration> _notificationOptions = [
    Duration.zero, // After expiration
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 6),
    const Duration(hours: 12),
    const Duration(days: 1),
    const Duration(days: 7),
    const Duration(days: 30),
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.domain?.url ?? '');
    if (widget.domain != null) {
      _selectedInterval = widget.domain!.checkInterval;
      _notifyBeforeExpiry = widget.domain!.notifyBeforeExpiry;
      _monitoringMode = widget.domain!.monitoringMode;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    }
  }

  String _formatNotificationDuration(Duration duration) {
    if (duration == Duration.zero) {
      return 'After expiration';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes before';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} before';
    } else {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} before';
    }
  }

  Future<void> _saveDomain() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url = _urlController.text.trim();
      DateTime? expiryDate;
      bool? isAvailable;

      // For new domains, check based on monitoring mode
      if (widget.domain == null) {
        // Check expiry if monitoring expiry
        if (_monitoringMode == MonitoringMode.expiryOnly || 
            _monitoringMode == MonitoringMode.both) {
          expiryDate = await RdapService.getDomainExpiry(url);
          
          if (expiryDate == null && _monitoringMode == MonitoringMode.expiryOnly) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not fetch domain expiration date via RDAP. Please check the domain name is correct.'),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            setState(() => _isSaving = false);
            return;
          }
        }
        
        // Check availability if monitoring availability
        if (_monitoringMode == MonitoringMode.availabilityOnly || 
            _monitoringMode == MonitoringMode.both) {
          isAvailable = await RdapService.isDomainAvailable(url);
        }
      }

      final domain = Domain(
        id: widget.domain?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        checkInterval: _selectedInterval,
        lastChecked: widget.domain == null ? DateTime.now().toUtc() : widget.domain?.lastChecked,
        expiryDate: expiryDate ?? widget.domain?.expiryDate,
        alarmId: widget.domain?.alarmId ?? StorageService.generateAlarmId(),
        notifyBeforeExpiry: _notifyBeforeExpiry,
        monitoringMode: _monitoringMode,
        isAvailable: isAvailable ?? widget.domain?.isAvailable,
        lastAvailabilityCheck: isAvailable != null ? DateTime.now().toUtc() : widget.domain?.lastAvailabilityCheck,
      );

      if (widget.domain == null) {
        await StorageService.addDomain(domain);
        
        // Send immediate notification about domain expiration (internally UTC, displayed in Asia/Dhaka)
        if (expiryDate != null) {
          final now = DateTime.now().toUtc();
          final daysUntilExpiry = expiryDate.difference(now).inDays;
          // Convert to Asia/Dhaka time (UTC+6) for display
          final dhakaTime = expiryDate.add(const Duration(hours: 6));
          final expiryDateStr = '${dhakaTime.year}-${dhakaTime.month.toString().padLeft(2, '0')}-${dhakaTime.day.toString().padLeft(2, '0')} '
              '${dhakaTime.hour.toString().padLeft(2, '0')}:${dhakaTime.minute.toString().padLeft(2, '0')} Asia/Dhaka';
          
          String message;
          if (daysUntilExpiry < 0) {
            final daysExpired = -daysUntilExpiry;
            message = 'Domain $url was added. It expired $daysExpired day${daysExpired != 1 ? 's' : ''} ago on $expiryDateStr.';
          } else if (daysUntilExpiry == 0) {
            final hoursUntilExpiry = expiryDate.difference(now).inHours;
            message = 'Domain $url was added. It expires today in $hoursUntilExpiry hour${hoursUntilExpiry != 1 ? 's' : ''} on $expiryDateStr!';
          } else {
            message = 'Domain $url was added. It expires on $expiryDateStr (in $daysUntilExpiry day${daysUntilExpiry != 1 ? 's' : ''}).';
          }
          
          await NotificationService.sendNotification(
            'Domain Added',
            message,
            type: NotificationType.expiry,
          );
        }
      } else {
        await StorageService.updateDomain(domain);
      }

      // Schedule alarm with deterministic alarm ID
      await AlarmService.scheduleAlarm(
        domain.alarmId,
        _selectedInterval,
        domain.url,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving domain: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.domain == null ? 'Add Domain' : 'Edit Domain'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Domain URL',
                hintText: 'example.com',
                prefixIcon: Icon(Icons.domain),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a domain URL';
                }
                if (!RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return 'Please enter a valid domain';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Monitoring Mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose what to monitor for this domain:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            RadioListTile<MonitoringMode>(
              title: const Text('Monitor Expiry Only'),
              subtitle: const Text('For domains you own - track expiration dates'),
              value: MonitoringMode.expiryOnly,
              groupValue: _monitoringMode,
              onChanged: (value) {
                setState(() {
                  _monitoringMode = value!;
                });
              },
            ),
            RadioListTile<MonitoringMode>(
              title: const Text('Monitor Availability Only'),
              subtitle: const Text('For domains you want - get notified when available'),
              value: MonitoringMode.availabilityOnly,
              groupValue: _monitoringMode,
              onChanged: (value) {
                setState(() {
                  _monitoringMode = value!;
                });
              },
            ),
            RadioListTile<MonitoringMode>(
              title: const Text('Monitor Both'),
              subtitle: const Text('Track both expiry and availability'),
              value: MonitoringMode.both,
              groupValue: _monitoringMode,
              onChanged: (value) {
                setState(() {
                  _monitoringMode = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Check Interval',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._intervalOptions.map((interval) {
              return RadioListTile<Duration>(
                title: Text(_formatDuration(interval)),
                value: interval,
                groupValue: _selectedInterval,
                onChanged: (value) {
                  setState(() {
                    _selectedInterval = value!;
                  });
                },
              );
            }),
            ListTile(
              title: const Text('Custom'),
              trailing: Text(
                _intervalOptions.contains(_selectedInterval)
                    ? ''
                    : _formatDuration(_selectedInterval),
              ),
              onTap: () {
                _showCustomIntervalDialog();
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Notification Timing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'When to receive notification:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Duration>(
              value: _notificationOptions.contains(_notifyBeforeExpiry)
                  ? _notifyBeforeExpiry
                  : _notificationOptions[0],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notifications_active),
                border: OutlineInputBorder(),
              ),
              items: _notificationOptions.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(_formatNotificationDuration(duration)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _notifyBeforeExpiry = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveDomain,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.domain == null ? 'Add Domain' : 'Update Domain',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomIntervalDialog() {
    int hours = _selectedInterval.inHours;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom Interval'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hours',
              hintText: 'Enter number of hours',
            ),
            onChanged: (value) {
              hours = int.tryParse(value) ?? 1;
            },
            controller: TextEditingController(text: hours.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedInterval = Duration(hours: hours);
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
