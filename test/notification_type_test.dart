import 'package:flutter_test/flutter_test.dart';
import 'package:domainpulse/services/notification_service.dart';

void main() {
  group('NotificationType Tests', () {
    test('NotificationType enum has correct values', () {
      expect(NotificationType.values.length, 2);
      expect(NotificationType.values.contains(NotificationType.expiry), true);
      expect(NotificationType.values.contains(NotificationType.availability), true);
    });

    test('NotificationType enum names are correct', () {
      expect(NotificationType.expiry.name, 'expiry');
      expect(NotificationType.availability.name, 'availability');
    });
  });
}
