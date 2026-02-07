import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../database/isar_database.dart';
import '../../data/entities/sync_queue_item.dart';
import '../../data/entities/order_entity.dart';
import '../../data/entities/sync_metadata.dart';

/// Sync operation result
class SyncResult {
  final bool success;
  final int itemsSynced;
  final int itemsFailed;
  final String? error;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.itemsSynced = 0,
    this.itemsFailed = 0,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Central sync engine managing offline-first synchronization
class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  final _connectivity = Connectivity();
  final _syncController = StreamController<SyncStatus>.broadcast();
  final _resultController = StreamController<SyncResult>.broadcast();

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _disposed = false;

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  /// Stream of sync results
  Stream<SyncResult> get syncResults => _resultController.stream;

  /// Whether currently syncing
  bool get isSyncing => _isSyncing;

  /// Initialize sync engine
  Future<void> initialize() async {
    if (_disposed) return;

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Start periodic sync
    _startPeriodicSync();

    // Initial sync if online
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await sync();
    }
  }

  /// Dispose resources
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    _syncController.close();
    _resultController.close();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    if (_disposed) return;

    if (result != ConnectivityResult.none) {
      // Back online - trigger sync
      sync();
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_disposed) sync();
    });
  }

  /// Main sync method
  Future<SyncResult> sync() async {
    if (_isSyncing || _disposed) {
      return SyncResult(
        success: false,
        error: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _syncController.add(SyncStatus.syncing);

    try {
      // Check connectivity
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return SyncResult(
          success: false,
          error: 'No internet connection',
        );
      }

      final db = await IsarDatabase.instance;
      final result = await _performSync(db);

      // Update metadata
      await db.writeTxn(() async {
        final meta = await db.syncMeta.get(1);
        if (meta != null) {
          meta.lastSyncAttempt = DateTime.now();
          if (result.success) {
            meta.lastFullSync = DateTime.now();
            meta.failedSyncAttempts = 0;
          } else {
            meta.failedSyncAttempts++;
          }
          await db.syncMeta.put(meta);
        }
      });

      _resultController.add(result);
      _syncController.add(result.success ? SyncStatus.synced : SyncStatus.error);

      return result;
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      _resultController.add(result);
      _syncController.add(SyncStatus.error);
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform actual sync
  Future<SyncResult> _performSync(Isar db) async {
    int synced = 0;
    int failed = 0;

    // 1. Process sync queue (high priority first)
    final queueItems = await db.syncQueue
        .where()
        .sortByPriority()
        .thenByCreatedAt()
        .findAll();

    for (final item in queueItems) {
      try {
        final success = await _processQueueItem(item);
        if (success) {
          synced++;
          await db.writeTxn(() => db.syncQueue.delete(item.id));
        } else {
          failed++;
          await _incrementRetry(db, item);
        }
      } catch (e) {
        failed++;
        await _incrementRetry(db, item, error: e.toString());
      }
    }

    // 2. Upload delivery proofs (photos)
    final pendingProofs = await db.orders
        .filter()
        .deliveryProofIsNotNull()
        .and()
        .deliveryProof((q) => q.photoUploadedEqualTo(false))
        .findAll();

    for (final order in pendingProofs) {
      try {
        final success = await _uploadDeliveryProof(order);
        if (success) {
          synced++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }
    }

    // 3. Fetch new orders from server
    try {
      await _fetchNewOrders(db);
    } catch (e) {
      // Non-critical, will retry next time
    }

    return SyncResult(
      success: failed == 0,
      itemsSynced: synced,
      itemsFailed: failed,
    );
  }

  /// Process single queue item
  Future<bool> _processQueueItem(SyncQueueItem item) async {
    // TODO: Implement actual API calls
    // This is a stub - replace with real API

    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network

    switch (item.entityType) {
      case 'order':
        return await _syncOrder(item);
      case 'location_update':
        return await _syncLocation(item);
      default:
        return true; // Unknown type, consider synced
    }
  }

  /// Sync order status to server
  Future<bool> _syncOrder(SyncQueueItem item) async {
    try {
      final url = Uri.parse('${_baseUrl}/driver/orders/${item.localId}/sync');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: item.payload,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sync location update
  Future<bool> _syncLocation(SyncQueueItem item) async {
    // Location updates are best-effort
    try {
      final url = Uri.parse('${_baseUrl}/driver/location');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: item.payload,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload delivery proof photo
  Future<bool> _uploadDeliveryProof(OrderEntity order) async {
    if (order.deliveryProof == null) return true;

    try {
      final file = File(order.deliveryProof!.photoPath);
      if (!await file.exists()) return true; // File missing, skip

      // TODO: Implement multipart upload
      // For now, mark as uploaded
      await _markPhotoUploaded(order.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch new orders from server
  Future<void> _fetchNewOrders(Isar db) async {
    final meta = await db.syncMeta.get(1);
    final lastSync = meta?.lastFullSync;

    // TODO: Call API to get new orders
    // final response = await http.get(...);

    // For now, just mark initial sync complete
    if (meta != null && !meta.initialSyncCompleted) {
      await db.writeTxn(() async {
        meta.initialSyncCompleted = true;
        await db.syncMeta.put(meta);
      });
    }
  }

  /// Increment retry count for failed item
  Future<void> _incrementRetry(Isar db, SyncQueueItem item,
      {String? error}) async {
    await db.writeTxn(() async {
      item.retryCount++;
      item.lastAttemptAt = DateTime.now();
      item.lastError = error;

      // Max 10 retries, then drop
      if (item.retryCount < 10) {
        await db.syncQueue.put(item);
      } else {
        await db.syncQueue.delete(item.id);
      }
    });
  }

  /// Mark photo as uploaded
  Future<void> _markPhotoUploaded(int orderId) async {
    final db = await IsarDatabase.instance;
    await db.writeTxn(() async {
      final order = await db.orders.get(orderId);
      if (order?.deliveryProof != null) {
        order!.deliveryProof!.photoUploaded = true;
        await db.orders.put(order);
      }
    });
  }

  // Base URL for API (should come from config)
  String get _baseUrl => 'https://api.deliverymaker.uz';
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
  offline,
}

/// Extension for convenient sync checks
extension SyncStatusExtension on SyncStatus {
  bool get isIdle => this == SyncStatus.idle;
  bool get isSyncing => this == SyncStatus.syncing;
  bool get isSynced => this == SyncStatus.synced;
  bool get hasError => this == SyncStatus.error;
  bool get isOffline => this == SyncStatus.offline;
}
