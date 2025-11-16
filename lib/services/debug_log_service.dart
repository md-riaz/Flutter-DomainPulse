import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/debug_log.dart';

class DebugLogService {
  static const String _logsFile = 'debug_logs.json';
  static const int _maxLogs = 500; // Limit to prevent unbounded growth
  static String? _dataPath;

  static Future<void> init() async {
    if (_dataPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _dataPath = directory.path;
    }
  }

  static Future<File> _getLogsFile() async {
    await init();
    return File('$_dataPath/$_logsFile');
  }

  static Future<List<DebugLog>> getLogs() async {
    try {
      final file = await _getLogsFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => DebugLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading debug logs: $e');
      return [];
    }
  }

  static Future<void> _saveLogs(List<DebugLog> logs) async {
    try {
      final file = await _getLogsFile();
      final jsonList = logs.map((log) => log.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving debug logs: $e');
    }
  }

  static Future<void> addLog(
    LogLevel level,
    String message, {
    String? details,
  }) async {
    try {
      final logs = await getLogs();
      
      final newLog = DebugLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().toUtc(),
        level: level,
        message: message,
        details: details,
      );
      
      logs.add(newLog);
      
      // Keep only the last _maxLogs entries
      if (logs.length > _maxLogs) {
        logs.removeRange(0, logs.length - _maxLogs);
      }
      
      await _saveLogs(logs);
      
      // Also log to debug console for development
      debugPrint('[${level.name.toUpperCase()}] $message');
      if (details != null) {
        debugPrint('  Details: $details');
      }
    } catch (e) {
      debugPrint('Error adding debug log: $e');
    }
  }

  static Future<void> clearLogs() async {
    try {
      final file = await _getLogsFile();
      if (await file.exists()) {
        await file.delete();
      }
      debugPrint('Debug logs cleared');
    } catch (e) {
      debugPrint('Error clearing debug logs: $e');
    }
  }

  static Future<int> getLogCount() async {
    final logs = await getLogs();
    return logs.length;
  }
}
