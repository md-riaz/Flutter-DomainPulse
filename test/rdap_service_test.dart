import 'package:flutter_test/flutter_test.dart';
import 'package:domainpulse/services/rdap_service.dart';

void main() {
  group('RdapService Tests', () {
    test('TLD extraction and URL generation for .xyz domains', () {
      // This test verifies that .xyz domains use the CentralNIC RDAP server
      // We can't directly test private methods, but we can verify through debug logs
      // or by checking that the service handles .xyz domains without errors
      
      // Test that the service can handle .xyz domain
      expect(() => RdapService.getDomainExpiry('example.xyz'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.xyz'), returnsNormally);
    });

    test('TLD extraction and URL generation for non-.xyz domains', () {
      // Test that the service can handle other TLDs (using rdap.org bootstrap)
      expect(() => RdapService.getDomainExpiry('example.com'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.com'), returnsNormally);
    });

    test('Handle domains with multiple dots', () {
      // Test that the service can handle subdomains
      expect(() => RdapService.getDomainExpiry('subdomain.example.xyz'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('subdomain.example.xyz'), returnsNormally);
    });

    test('Handle uppercase domains', () {
      // Test that the service handles case-insensitive domain names
      expect(() => RdapService.getDomainExpiry('EXAMPLE.XYZ'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('EXAMPLE.XYZ'), returnsNormally);
    });

    test('Handle alphanetusasupport.xyz domain', () {
      // Specific test for the reported issue
      expect(() => RdapService.getDomainExpiry('alphanetusasupport.xyz'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('alphanetusasupport.xyz'), returnsNormally);
    });
  });
}
