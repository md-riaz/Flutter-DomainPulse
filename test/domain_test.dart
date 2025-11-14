import 'package:flutter_test/flutter_test.dart';
import 'package:domainpulse/models/domain.dart';

void main() {
  group('Domain Model Tests', () {
    test('Domain toJson and fromJson', () {
      final domain = Domain(
        id: '123',
        url: 'example.com',
        checkInterval: const Duration(hours: 1),
        lastChecked: DateTime(2024, 1, 1, 12, 0),
        expiryDate: DateTime(2024, 12, 31, 23, 59),
        alarmId: 1001,
        notifyBeforeExpiry: const Duration(hours: 6),
      );

      final json = domain.toJson();
      final decoded = Domain.fromJson(json);

      expect(decoded.id, domain.id);
      expect(decoded.url, domain.url);
      expect(decoded.checkInterval, domain.checkInterval);
      expect(decoded.lastChecked, domain.lastChecked);
      expect(decoded.expiryDate, domain.expiryDate);
      expect(decoded.alarmId, domain.alarmId);
      expect(decoded.notifyBeforeExpiry, domain.notifyBeforeExpiry);
    });

    test('Domain copyWith', () {
      final domain = Domain(
        id: '123',
        url: 'example.com',
        checkInterval: const Duration(hours: 1),
        alarmId: 1002,
        notifyBeforeExpiry: const Duration(hours: 1),
      );

      final updated = domain.copyWith(
        url: 'newexample.com',
        expiryDate: DateTime(2024, 12, 31),
        notifyBeforeExpiry: const Duration(days: 1),
      );

      expect(updated.id, domain.id);
      expect(updated.url, 'newexample.com');
      expect(updated.checkInterval, domain.checkInterval);
      expect(updated.expiryDate, DateTime(2024, 12, 31));
      expect(updated.alarmId, domain.alarmId);
      expect(updated.notifyBeforeExpiry, const Duration(days: 1));
    });

    test('Domain with null dates', () {
      final domain = Domain(
        id: '123',
        url: 'example.com',
        checkInterval: const Duration(hours: 1),
        alarmId: 1003,
        notifyBeforeExpiry: const Duration(hours: 1),
      );

      final json = domain.toJson();
      final decoded = Domain.fromJson(json);

      expect(decoded.lastChecked, isNull);
      expect(decoded.expiryDate, isNull);
      expect(decoded.alarmId, 1003);
      expect(decoded.notifyBeforeExpiry, const Duration(hours: 1));
    });

    test('Domain defaults notifyBeforeExpiry to 1 hour when missing', () {
      final json = {
        'id': '123',
        'url': 'example.com',
        'checkInterval': 3600,
        'alarmId': 1004,
      };

      final domain = Domain.fromJson(json);

      expect(domain.notifyBeforeExpiry, const Duration(hours: 1));
    });
  });
}
