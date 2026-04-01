import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'domain_check_service.dart';
import 'notification_service.dart';
import 'debug_log_service.dart';
import 'storage_service.dart';
import '../models/debug_log.dart';

const String kDomainSyncTaskName = 'domainpulse_background_sync';

@pragma('vm:entry-point')
void domainPulseWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await StorageService.init();
      await DebugLogService.init();
      await NotificationService.initialize(isBackgroundContext: true);

      await DebugLogService.addLog(
        LogLevel.info,
        'WorkManager task started',
        details: 'Task: $task\nTimestamp: ${DateTime.now().toUtc()}',
      );

      await DomainCheckService.checkDueDomains();

      await DebugLogService.addLog(
        LogLevel.success,
        'WorkManager task completed',
        details: 'Task: $task\nTimestamp: ${DateTime.now().toUtc()}',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('WorkManager task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      try {
        await DebugLogService.init();
        await DebugLogService.addLog(
          LogLevel.error,
          'WorkManager task failed',
          details: 'Task: $task\nError: $e\nStack trace: $stackTrace',
        );
      } catch (_) {}
      return false;
    }
  });
}

class WorkmanagerService {
  static const String _periodicTaskUniqueName = 'domainpulse_periodic_sync';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(
      domainPulseWorkmanagerCallbackDispatcher,
      isInDebugMode: false,
    );
    _initialized = true;
  }

  static Future<void> registerBackgroundSync() async {
    await initialize();
    // WorkManager periodic work has a practical floor on Android.
    // Per-domain intervals are enforced by DomainCheckService.checkDueDomains().
    await Workmanager().registerPeriodicTask(
      _periodicTaskUniqueName,
      kDomainSyncTaskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
