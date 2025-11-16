import 'package:flutter_test/flutter_test.dart';
import 'package:domainpulse/models/debug_log.dart';

void main() {
  group('DebugLog Model Tests', () {
    test('DebugLog toJson and fromJson', () {
      final log = DebugLog(
        id: '123',
        timestamp: DateTime(2024, 1, 1, 12, 0).toUtc(),
        level: LogLevel.success,
        message: 'Test message',
        details: 'Test details',
      );

      final json = log.toJson();
      final decoded = DebugLog.fromJson(json);

      expect(decoded.id, log.id);
      expect(decoded.timestamp, log.timestamp);
      expect(decoded.level, log.level);
      expect(decoded.message, log.message);
      expect(decoded.details, log.details);
    });

    test('DebugLog without details', () {
      final log = DebugLog(
        id: '456',
        timestamp: DateTime(2024, 1, 2, 10, 30).toUtc(),
        level: LogLevel.info,
        message: 'Info message',
      );

      final json = log.toJson();
      final decoded = DebugLog.fromJson(json);

      expect(decoded.id, '456');
      expect(decoded.message, 'Info message');
      expect(decoded.details, isNull);
      expect(decoded.level, LogLevel.info);
    });

    test('LogLevel enum has correct values', () {
      expect(LogLevel.values.length, 4);
      expect(LogLevel.values.contains(LogLevel.info), true);
      expect(LogLevel.values.contains(LogLevel.success), true);
      expect(LogLevel.values.contains(LogLevel.error), true);
      expect(LogLevel.values.contains(LogLevel.warning), true);
    });

    test('LogLevel enum names are correct', () {
      expect(LogLevel.info.name, 'info');
      expect(LogLevel.success.name, 'success');
      expect(LogLevel.error.name, 'error');
      expect(LogLevel.warning.name, 'warning');
    });

    test('DebugLog with error level', () {
      final log = DebugLog(
        id: '789',
        timestamp: DateTime(2024, 1, 3, 14, 45).toUtc(),
        level: LogLevel.error,
        message: 'Error occurred',
        details: 'Stack trace here',
      );

      final json = log.toJson();
      final decoded = DebugLog.fromJson(json);

      expect(decoded.level, LogLevel.error);
      expect(decoded.message, 'Error occurred');
      expect(decoded.details, 'Stack trace here');
    });

    test('DebugLog with warning level', () {
      final log = DebugLog(
        id: '101',
        timestamp: DateTime(2024, 1, 4, 9, 15).toUtc(),
        level: LogLevel.warning,
        message: 'Warning message',
      );

      final json = log.toJson();
      final decoded = DebugLog.fromJson(json);

      expect(decoded.level, LogLevel.warning);
      expect(decoded.message, 'Warning message');
    });
  });
}
