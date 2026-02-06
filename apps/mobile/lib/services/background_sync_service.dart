import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'sync_service.dart';
import 'api_service.dart';

// Unique name for background task
const String syncTaskName = 'deliverymaker.background.sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background sync task started');
      
      // Initialize services
      final db = DatabaseService();
      await db.init();
      
      final api = ApiService();
      final sync = SyncService(api, db);
      
      // Perform sync
      await sync.pushData();
      await sync.pullData();
      
      debugPrint('Background sync completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('Background sync failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    _isInitialized = true;
  }

  Future<void> registerPeriodicSync() async {
    if (!_isInitialized) await initialize();

    // Cancel existing tasks
    await Workmanager().cancelAll();

    // Register periodic sync every 15 minutes (minimum allowed)
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint('Periodic sync registered');
  }

  Future<void> cancelSync() async {
    if (!_isInitialized) return;
    await Workmanager().cancelByUniqueName(syncTaskName);
  }

  Future<void> triggerImmediateSync() async {
    if (!_isInitialized) await initialize();

    await Workmanager().registerOneOffTask(
      '${syncTaskName}.immediate',
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
