import 'package:flutter_test/flutter_test.dart';
import 'package:domainpulse/services/alarm_permission_service.dart';

void main() {
  group('AlarmPermissionService (WorkManager migration)', () {
    test('exact alarm permission is treated as not required', () async {
      expect(await AlarmPermissionService.checkAlarmPermission(), isTrue);
      expect(await AlarmPermissionService.requestAlarmPermission(), isTrue);
      expect(await AlarmPermissionService.requiresAlarmPermission(), isFalse);
      expect(
        await AlarmPermissionService.getPermissionStatusMessage(),
        contains('not required'),
      );
    });
  });
}
