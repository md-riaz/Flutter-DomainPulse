import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/domain.dart';

class StorageService {
  static late String _dataPath;
  static const String _domainsFile = 'domains.json';
  static const String _settingsFile = 'settings.json';

  static Future<void> init() async {
    // In a real app, use path_provider. For simplicity, use /tmp
    _dataPath = '/tmp/domainpulse';
    final dir = Directory(_dataPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static Future<File> _getDomainsFile() async {
    return File('$_dataPath/$_domainsFile');
  }

  static Future<File> _getSettingsFile() async {
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

  static Future<String?> getNtfyTopic() async {
    try {
      final file = await _getSettingsFile();
      if (!await file.exists()) {
        return null;
      }
      final contents = await file.readAsString();
      final Map<String, dynamic> settings = json.decode(contents);
      return settings['ntfyTopic'] as String?;
    } catch (e) {
      debugPrint('Error loading ntfy topic: $e');
      return null;
    }
  }

  static Future<void> setNtfyTopic(String topic) async {
    try {
      final file = await _getSettingsFile();
      Map<String, dynamic> settings = {};
      if (await file.exists()) {
        final contents = await file.readAsString();
        settings = json.decode(contents);
      }
      settings['ntfyTopic'] = topic;
      await file.writeAsString(json.encode(settings));
    } catch (e) {
      debugPrint('Error saving ntfy topic: $e');
    }
  }
}
