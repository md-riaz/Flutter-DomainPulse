import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service for checking domain expiration and availability using RDAP (Registration Data Access Protocol)
class RdapService {
  /// Map of TLD-specific RDAP servers
  /// Using authoritative RDAP servers for better reliability
  static const Map<String, String> _tldRdapServers = {
    // Generic TLDs (gTLDs)
    'com': 'https://rdap.verisign.com/com/v1',
    'net': 'https://rdap.verisign.com/net/v1',
    'org': 'https://rdap.publicinterestregistry.org/rdap',
    'info': 'https://rdap.afilias-srs.net/rdap/info',
    'biz': 'https://rdap.afilias-srs.net/rdap/biz',

    // New gTLDs managed by various registries
    'xyz': 'https://rdap.centralnic.com/xyz',
    'online': 'https://rdap.centralnic.com/online',
    'site': 'https://rdap.centralnic.com/site',
    'store': 'https://rdap.centralnic.com/store',
    'tech': 'https://rdap.centralnic.com/tech',
    'cloud': 'https://rdap.centralnic.com/cloud',
    'app': 'https://rdap.google.com',
    'dev': 'https://rdap.google.com',
    'page': 'https://rdap.google.com',
    'io': 'https://rdap.identitydigital.services/rdap',
    'co': 'https://rdap.identitydigital.services/rdap',
    'me': 'https://rdap.identitydigital.services/rdap',
    'tv': 'https://rdap.identitydigital.services/rdap',
    'us': 'https://rdap.identitydigital.services/rdap',
    'cc': 'https://rdap.identitydigital.services/rdap',
    'mobi': 'https://rdap.afilias-srs.net/rdap/mobi',
    'pro': 'https://rdap.afilias-srs.net/rdap/pro',
    'name': 'https://rdap.verisign.com/name/v1',
    'ai': 'https://rdap.identitydigital.services/rdap',
    'link': 'https://rdap.uniregistry.net',
    'click': 'https://rdap.uniregistry.net',
  };

  /// Extract the TLD from a domain name
  /// Returns the TLD in lowercase (e.g., 'xyz' from 'example.xyz')
  static String _getTld(String domain) {
    final parts = domain.toLowerCase().split('.');
    return parts.isNotEmpty ? parts.last : '';
  }

  /// Get the appropriate RDAP server URL for a domain
  /// Uses TLD-specific servers when available, falls back to rdap.org bootstrap
  static String _getRdapUrl(String domain) {
    final tld = _getTld(domain);
    final tldServer = _tldRdapServers[tld];
    
    if (tldServer != null) {
      return '$tldServer/domain/${Uri.encodeComponent(domain)}';
    }
    
    // Fallback to rdap.org bootstrap service
    return 'https://rdap.org/domain/${Uri.encodeComponent(domain)}';
  }
  /// Check if a domain is available for registration
  /// Returns true if available, false if registered, null if unknown
  static Future<bool?> isDomainAvailable(String domain) async {
    try {
      final url = _getRdapUrl(domain);
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
      final url = _getRdapUrl(domain);
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
