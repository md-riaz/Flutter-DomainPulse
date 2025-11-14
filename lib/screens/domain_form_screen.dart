import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';

class DomainFormScreen extends StatefulWidget {
  final Domain? domain;

  const DomainFormScreen({super.key, this.domain});

  @override
  State<DomainFormScreen> createState() => _DomainFormScreenState();
}

class _DomainFormScreenState extends State<DomainFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _expiryController;
  Duration _selectedInterval = const Duration(hours: 1);
  DateTime? _selectedExpiryDate;

  final List<Duration> _intervalOptions = [
    const Duration(minutes: 15),
    const Duration(hours: 1),
    const Duration(hours: 6),
    const Duration(days: 1),
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.domain?.url ?? '');
    _selectedExpiryDate = widget.domain?.expiryDate;
    _expiryController = TextEditingController(
      text: _selectedExpiryDate != null
          ? '${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month.toString().padLeft(2, '0')}-${_selectedExpiryDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
    if (widget.domain != null) {
      _selectedInterval = widget.domain!.checkInterval;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _expiryController.dispose();
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

  Future<void> _saveDomain() async {
    if (_formKey.currentState!.validate()) {
      final domain = Domain(
        id: widget.domain?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        url: _urlController.text.trim(),
        checkInterval: _selectedInterval,
        lastChecked: widget.domain?.lastChecked,
        expiryDate: _selectedExpiryDate,
      );

      if (widget.domain == null) {
        await StorageService.addDomain(domain);
      } else {
        await StorageService.updateDomain(domain);
      }

      // Schedule alarm
      await AlarmService.scheduleAlarm(
        domain.id.hashCode,
        _selectedInterval,
        domain.url,
      );

      if (mounted) {
        Navigator.pop(context);
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
            TextFormField(
              controller: _expiryController,
              decoration: InputDecoration(
                labelText: 'Expiry Date (Optional)',
                hintText: 'YYYY-MM-DD',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedExpiryDate = date;
                        _expiryController.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final date = DateTime.tryParse(value);
                  if (date == null) {
                    return 'Please enter a valid date (YYYY-MM-DD)';
                  }
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _selectedExpiryDate = DateTime.tryParse(value);
                } else {
                  _selectedExpiryDate = null;
                }
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
            ElevatedButton(
              onPressed: _saveDomain,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
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
