import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service for checking domain expiration using RDAP (Registration Data Access Protocol)
class RdapService {
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
