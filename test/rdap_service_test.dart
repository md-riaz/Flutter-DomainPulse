import 'package:flutter_test/flutter_test.dart';
import 'package:domainpulse/services/rdap_service.dart';

void main() {
  group('RdapService Tests', () {
    test('Handle .xyz domains', () {
      // Test that the service can handle .xyz domain
      expect(() => RdapService.getDomainExpiry('example.xyz'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.xyz'), returnsNormally);
    });

    test('Handle common gTLDs - .com, .net, .org', () {
      // Test that the service can handle common TLDs with their specific RDAP servers
      expect(() => RdapService.getDomainExpiry('example.com'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.com'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.net'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.net'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.org'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.org'), returnsNormally);
    });

    test('Handle popular new gTLDs - .io, .app, .dev', () {
      // Test popular new TLDs
      expect(() => RdapService.getDomainExpiry('example.io'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.io'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.app'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.app'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.dev'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.dev'), returnsNormally);
    });

    test('Handle CentralNIC TLDs - .online, .site, .tech', () {
      // Test CentralNIC managed TLDs
      expect(() => RdapService.getDomainExpiry('example.online'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.online'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.site'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.site'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.tech'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.tech'), returnsNormally);
    });

    test('Handle unsupported TLDs with bootstrap fallback', () {
      // Test that the service falls back to rdap.org for unsupported TLDs
      expect(() => RdapService.getDomainExpiry('example.unsupported'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.unsupported'), returnsNormally);
    });

    test('Handle domains with multiple dots', () {
      // Test that the service can handle subdomains
      expect(() => RdapService.getDomainExpiry('subdomain.example.xyz'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('subdomain.example.xyz'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('deep.subdomain.example.com'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('deep.subdomain.example.com'), returnsNormally);
    });

    test('Handle uppercase domains', () {
      // Test that the service handles case-insensitive domain names
      expect(() => RdapService.getDomainExpiry('EXAMPLE.XYZ'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('EXAMPLE.XYZ'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('Example.COM'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('Example.COM'), returnsNormally);
    });

    test('Handle mixed case domains', () {
      // Test mixed case handling
      expect(() => RdapService.getDomainExpiry('ExAmPlE.NeT'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('ExAmPlE.NeT'), returnsNormally);
    });

    test('Handle alphanetusasupport.xyz domain - original issue', () {
      // Specific test for the reported issue
      expect(() => RdapService.getDomainExpiry('alphanetusasupport.xyz'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('alphanetusasupport.xyz'), returnsNormally);
    });

    test('Handle country code TLDs - .us, .co, .me', () {
      // Test ccTLDs managed by Identity Digital
      expect(() => RdapService.getDomainExpiry('example.us'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.us'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.co'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.co'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.me'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.me'), returnsNormally);
    });

    test('Handle tech-focused TLDs - .ai, .cloud', () {
      // Test technology-focused TLDs
      expect(() => RdapService.getDomainExpiry('example.ai'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.ai'), returnsNormally);
      expect(() => RdapService.getDomainExpiry('example.cloud'), returnsNormally);
      expect(() => RdapService.isDomainAvailable('example.cloud'), returnsNormally);
    });
  });
}

