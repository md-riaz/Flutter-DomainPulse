import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/domain.dart';

class StorageService {
  static String? _dataPath;
  static const String _domainsFile = 'domains.json';
  static const String _settingsFile = 'settings.json';
  static int _nextAlarmId = 1000;

  static Future<void> init() async {
    if (_dataPath == null) {
      // Use path_provider for proper Android storage
      final directory = await getApplicationDocumentsDirectory();
      _dataPath = directory.path;
      debugPrint('StorageService initialized with path: $_dataPath');
      
      // Load the next alarm ID from storage
      await _loadNextAlarmId();
    }
  }

  static Future<void> _loadNextAlarmId() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> settings = json.decode(contents);
        _nextAlarmId = settings['nextAlarmId'] as int? ?? 1000;
      }
    } catch (e) {
      debugPrint('Error loading nextAlarmId: $e');
      _nextAlarmId = 1000;
    }
  }

  static Future<void> _saveNextAlarmId() async {
    try {
      final file = await _getSettingsFile();
      Map<String, dynamic> settings = {};
      if (await file.exists()) {
        final contents = await file.readAsString();
        settings = json.decode(contents);
      }
      settings['nextAlarmId'] = _nextAlarmId;
      await file.writeAsString(json.encode(settings));
    } catch (e) {
      debugPrint('Error saving nextAlarmId: $e');
    }
  }

  static int generateAlarmId() {
    final id = _nextAlarmId++;
    _saveNextAlarmId();
    return id;
  }

  static Future<File> _getDomainsFile() async {
    // Always ensure initialization before accessing file
    await init();
    if (_dataPath == null) {
      throw Exception('StorageService: _dataPath is null after init()');
    }
    return File('$_dataPath/$_domainsFile');
  }

  static Future<File> _getSettingsFile() async {
    // Always ensure initialization before accessing file
    await init();
    if (_dataPath == null) {
      throw Exception('StorageService: _dataPath is null after init()');
    }
    return File('$_dataPath/$_settingsFile');
  }

  static Future<List<Domain>> getDomains() async {
    try {
      final file = await _getDomainsFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => Domain.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading domains: $e');
      return [];
    }
  }

  static Future<void> saveDomains(List<Domain> domains) async {
    try {
      final file = await _getDomainsFile();
      final jsonList = domains.map((d) => d.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving domains: $e');
    }
  }

  static Future<void> addDomain(Domain domain) async {
    final domains = await getDomains();
    domains.add(domain);
    await saveDomains(domains);
  }

  static Future<void> updateDomain(Domain domain) async {
    final domains = await getDomains();
    final index = domains.indexWhere((d) => d.id == domain.id);
    if (index != -1) {
      domains[index] = domain;
      await saveDomains(domains);
    }
  }

  static Future<void> deleteDomain(String id) async {
    final domains = await getDomains();
    domains.removeWhere((d) => d.id == id);
    await saveDomains(domains);
  }
}
