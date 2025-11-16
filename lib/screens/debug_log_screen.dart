import 'package:flutter/material.dart';
import '../models/debug_log.dart';
import '../services/debug_log_service.dart';
import 'alarm_diagnostics_screen.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  List<DebugLog> _logs = [];
  bool _isLoading = false;
  LogLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await DebugLogService.getLogs();
    setState(() {
      // Show newest first
      _logs = logs.reversed.toList();
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Debug Logs'),
        content: const Text('Are you sure you want to clear all debug logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DebugLogService.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debug logs cleared')),
        );
      }
    }
  }

  List<DebugLog> get _filteredLogs {
    if (_filterLevel == null) {
      return _logs;
    }
    return _logs.where((log) => log.level == _filterLevel).toList();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
    }
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.success:
        return Icons.check_circle_outline;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlarmDiagnosticsScreen(),
                ),
              );
            },
            tooltip: 'Alarm Diagnostics',
          ),
          PopupMenuButton<LogLevel?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by level',
            onSelected: (level) {
              setState(() => _filterLevel = level);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: LogLevel.info,
                child: Text('Info'),
              ),
              const PopupMenuItem(
                value: LogLevel.success,
                child: Text('Success'),
              ),
              const PopupMenuItem(
                value: LogLevel.warning,
                child: Text('Warning'),
              ),
              const PopupMenuItem(
                value: LogLevel.error,
                child: Text('Error'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterLevel == null
                            ? 'No debug logs yet'
                            : 'No ${_filterLevel!.name} logs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Logs will appear here as domain checks run',
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary bar
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Total: ${_logs.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_filterLevel != null)
                            Text(
                              'Filtered: ${filteredLogs.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                        ],
                      ),
                    ),
                    // Logs list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final levelColor = _getLevelColor(log.level);
                          final levelIcon = _getLevelIcon(log.level);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ExpansionTile(
                              leading: Icon(
                                levelIcon,
                                color: levelColor,
                              ),
                              title: Text(
                                log.message,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: levelColor,
                                ),
                              ),
                              subtitle: Text(
                                _formatDateTime(log.timestamp),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              children: [
                                if (log.details != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        log.details!,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }
}
