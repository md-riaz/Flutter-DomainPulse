import 'package:flutter/foundation.dart';
import 'workmanager_service.dart';

class BackgroundSyncService {
  static Future<void> registerOrUpdateSync() async {
    debugPrint('Registering WorkManager background sync');
    await WorkmanagerService.registerBackgroundSync();
  }

  static Future<void> domainRemoved(String domainId) async {
    debugPrint('Domain removed: $domainId. WorkManager sync remains active.');
  }
}
