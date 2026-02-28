import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundSyncService {
  static const String syncTaskName = 'alerts_offline_sync_task';

  Future<void> initialize() async {
    await Workmanager().initialize(_dispatcher, isInDebugMode: false);
  }

  Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 5),
    );
  }

  @pragma('vm:entry-point')
  static void _dispatcher() {
    Workmanager().executeTask((taskName, inputData) async {
      if (taskName == syncTaskName) {
        // Placeholder for alert cache sync.
      }
      return Future.value(true);
    });
  }
}

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService();
});
