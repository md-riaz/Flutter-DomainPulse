import 'package:flutter/material.dart';
import '../services/alarm_diagnostic_service.dart';
import '../services/debug_log_service.dart';
import '../models/debug_log.dart';

class AlarmDiagnosticsScreen extends StatefulWidget {
  const AlarmDiagnosticsScreen({super.key});

  @override
  State<AlarmDiagnosticsScreen> createState() => _AlarmDiagnosticsScreenState();
}

class _AlarmDiagnosticsScreenState extends State<AlarmDiagnosticsScreen> {
  Map<String, dynamic>? _diagnosticResults;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isRunning = true);
    final results = await AlarmDiagnosticService.runDiagnostics();
    setState(() {
      _diagnosticResults = results;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Diagnostics'),
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
                  // Diagnostic info card
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
                                'Alarm System Status',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_diagnosticResults != null) ...[
                            _buildStatusRow(
                              'Alarm Manager Initialized',
                              _diagnosticResults!['alarm_manager_initialized'] == true,
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
                  
                  // Common issues card
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
                            'Android 12+ (API 31+)',
                            'If you\'re on Android 12 or higher, the app requires SCHEDULE_EXACT_ALARM permission. Check your device Settings > Apps > DomainPulse > Permissions.',
                          ),
                          _buildIssueItem(
                            'Battery Optimization',
                            'Some devices may kill background alarms to save battery. Go to Settings > Battery > Battery Optimization and set DomainPulse to "Not optimized" or "Unrestricted".',
                          ),
                          _buildIssueItem(
                            'Device Manufacturer Restrictions',
                            'Some manufacturers (Xiaomi, Huawei, Samsung, OnePlus) have aggressive battery management. You may need to:\n• Enable "Autostart" for this app\n• Disable "Battery optimization"\n• Add app to "Protected apps" list',
                          ),
                          _buildIssueItem(
                            'Short Intervals (<15min)',
                            'Android may defer alarms shorter than 15 minutes to save battery. Use longer intervals or check debug logs to see actual trigger times.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Troubleshooting steps card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.build, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Troubleshooting Steps',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildStep('1', 'Add a domain with a short interval (e.g., 15 minutes)'),
                          _buildStep('2', 'Check debug logs (bug report icon) immediately after adding'),
                          _buildStep('3', 'Wait for the interval to pass and check logs again'),
                          _buildStep('4', 'If no alarm fired, check battery optimization settings'),
                          _buildStep('5', 'Try increasing the interval to 1 hour and test again'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick actions
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
                                details: 'User opened diagnostics screen and ran manual check',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Diagnostic entry added to debug logs'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.note_add),
                            label: const Text('Add Test Log Entry'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.bug_report),
                            label: const Text('View Debug Logs'),
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

  Widget _buildStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(description),
            ),
          ),
        ],
      ),
    );
  }
}
