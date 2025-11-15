import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service for checking domain expiration and availability using RDAP (Registration Data Access Protocol)
class RdapService {
  /// Check if a domain is available for registration
  /// Returns true if available, false if registered, null if unknown
  static Future<bool?> isDomainAvailable(String domain) async {
    try {
      final url = 'https://rdap.org/domain/${Uri.encodeComponent(domain)}';
      debugPrint('Checking domain availability from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DomainPulse/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      // If status is 404, domain is not registered (available)
      if (response.statusCode == 404) {
        debugPrint('Domain $domain is available (404 response)');
        return true;
      }

      // If status is 200, domain is registered (not available)
      if (response.statusCode == 200) {
        debugPrint('Domain $domain is registered (200 response)');
        return false;
      }

      // Other status codes mean we can't determine availability
      debugPrint('RDAP request returned status ${response.statusCode}, availability unknown');
      return null;
    } catch (e) {
      debugPrint('Error checking domain availability for $domain: $e');
      return null;
    }
  }

  /// Get domain expiry date from RDAP
  /// Returns the expiry date in UTC or null if not found
  static Future<DateTime?> getDomainExpiry(String domain) async {
    try {
      final url = 'https://rdap.org/domain/${Uri.encodeComponent(domain)}';
      debugPrint('Fetching RDAP data from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DomainPulse/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('RDAP request failed with status: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      // Look for the expiration event in the events array
      if (data.containsKey('events')) {
        final events = data['events'] as List<dynamic>;
        for (final event in events) {
          if (event is Map<String, dynamic>) {
            final eventAction = event['eventAction'] as String?;
            if (eventAction == 'expiration') {
              final eventDate = event['eventDate'] as String?;
              if (eventDate != null) {
                // Parse ISO8601 UTC date
                final expiryDate = DateTime.parse(eventDate);
                debugPrint('Found expiry date: $expiryDate UTC for domain: $domain');
                return expiryDate.toUtc();
              }
            }
          }
        }
      }

      debugPrint('No expiration event found in RDAP data for domain: $domain');
      return null;
    } catch (e) {
      debugPrint('Error fetching RDAP data for $domain: $e');
      return null;
    }
  }
}
