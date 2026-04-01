import 'package:flutter/material.dart';
import '../services/background_diagnostic_service.dart';
import '../services/debug_log_service.dart';
import '../models/debug_log.dart';

class BackgroundDiagnosticsScreen extends StatefulWidget {
  const BackgroundDiagnosticsScreen({super.key});

  @override
  State<BackgroundDiagnosticsScreen> createState() =>
      _BackgroundDiagnosticsScreenState();
}

class _BackgroundDiagnosticsScreenState extends State<BackgroundDiagnosticsScreen> {
  Map<String, dynamic>? _diagnosticResults;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isRunning = true);
    final results = await BackgroundDiagnosticService.runDiagnostics();
    setState(() {
      _diagnosticResults = results;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Diagnostics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: 'Run diagnostics again',
          ),
        ],
      ),
      body: _isRunning
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Background Sync Status',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_diagnosticResults != null) ...[
                            _buildStatusRow(
                              'WorkManager Initialized',
                              _diagnosticResults!['workmanager_initialized'] ==
                                  true,
                            ),
                            _buildStatusRow(
                              'Exact Alarm Not Required',
                              _diagnosticResults!['exact_alarm_not_required'] ==
                                  true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last checked: ${_diagnosticResults!['checks_performed']}',
                              style: Theme.of(context).textTheme.bodySmall,
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
                          Row(
                            children: [
                              const Icon(Icons.warning_amber, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Common Issues & Solutions',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildIssueItem(
                            'WorkManager scheduling',
                            'DomainPulse uses WorkManager for background checks and does not require SCHEDULE_EXACT_ALARM.',
                          ),
                          _buildIssueItem(
                            'Foreground service permission',
                            'FOREGROUND_SERVICE is not required for this periodic WorkManager background sync path.',
                          ),
                          _buildIssueItem(
                            'Battery Optimization',
                            'Some devices may kill background tasks to save battery. Set DomainPulse to "Not optimized" or "Unrestricted".',
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
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await DebugLogService.addLog(
                                LogLevel.info,
                                'Manual diagnostic check triggered by user',
                                details:
                                    'User opened background diagnostics screen and ran manual check',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Diagnostic entry added to debug logs',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.note_add),
                            label: const Text('Add Test Log Entry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, bool isHealthy) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHealthy ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          isHealthy ? 'OK' : 'FAILED',
          style: TextStyle(
            color: isHealthy ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIssueItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
