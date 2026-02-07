import 'dart:convert';
import 'package:isar/isar.dart';
import '../../core/database/isar_database.dart';
import '../../core/sync/sync_engine.dart';
import '../entities/order_entity.dart';
import '../entities/sync_queue_item.dart';

/// Repository for Order operations with offline-first support
/// 
/// All operations work locally first, then sync to server
class OrderRepository {
  final _syncEngine = SyncEngine();

  /// Get orders assigned to driver
  /// Returns cached data immediately, syncs in background
  Future<List<OrderEntity>> getDriverOrders(String driverId,
      {DateTime? date}) async {
    final db = await IsarDatabase.instance;

    // Get from local database
    var query = db.orders.filter().driverIdEqualTo(driverId);

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .deliveryDateBetween(startOfDay, endOfDay, includeLower: true);
    }

    final orders = await query.sortByDeliveryDate().findAll();

    // Trigger background sync
    _syncEngine.sync();

    return orders;
  }

  /// Get order by ID
  Future<OrderEntity?> getOrderById(String orderId) async {
    final db = await IsarDatabase.instance;

    // Try by server ID first
    var order = await db.orders.filter().serverIdEqualTo(orderId).findFirst();

    // Fall back to local ID
    order ??= await db.orders.filter().orderCodeEqualTo(orderId).findFirst();

    return order;
  }

  /// Mark order as picked up
  /// Works offline, syncs when online
  Future<void> markAsPickedUp(String orderId) async {
    final db = await IsarDatabase.instance;

    await db.writeTxn(() async {
      final order = await _findOrder(db, orderId);
      if (order == null) return;

      order.markAsPickedUp();
      await db.orders.put(order);

      // Add to sync queue
      await _queueOrderUpdate(db, order, 'pickup');
    });

    // Trigger sync
    _syncEngine.sync();
  }

  /// Mark order as delivered with proof
  /// Works offline, syncs when online
  Future<void> markAsDelivered(
    String orderId,
    DeliveryProof proof,
  ) async {
    final db = await IsarDatabase.instance;

    await db.writeTxn(() async {
      final order = await _findOrder(db, orderId);
      if (order == null) return;

      order.markAsDelivered(proof);
      await db.orders.put(order);

      // Add to sync queue with high priority
      await _queueOrderUpdate(
        db,
        order,
        'deliver',
        priority: 1, // High priority
        syncImmediately: true,
      );
    });

    // Trigger immediate sync for delivery
    _syncEngine.sync();
  }

  /// Save orders from server (after fetch)
  Future<void> saveOrdersFromServer(List<OrderEntity> orders) async {
    final db = await IsarDatabase.instance;

    await db.writeTxn(() async {
      for (final order in orders) {
        // Check if already exists
        final existing = await db.orders
            .filter()
            .serverIdEqualTo(order.serverId)
            .findFirst();

        if (existing != null) {
          // Update only if server version is newer
          if (order.version > existing.version) {
            order.id = existing.id; // Preserve local ID
            order.syncStatus = SyncStatus()
              ..isSynced = true
              ..serverId = order.serverId;
            await db.orders.put(order);
          }
        } else {
          // New order
          order.syncStatus = SyncStatus()
            ..isSynced = true
            ..serverId = order.serverId;
          await db.orders.put(order);
        }
      }
    });
  }

  /// Get pending deliveries count
  Future<int> getPendingCount(String driverId) async {
    final db = await IsarDatabase.instance;
    return await db.orders
        .filter()
        .driverIdEqualTo(driverId)
        .and()
        .not()
        .statusEqualTo('delivered')
        .and()
        .not()
        .statusEqualTo('cancelled')
        .count();
  }

  /// Get today's stats
  Future<OrderStats> getTodayStats(String driverId) async {
    final db = await IsarDatabase.instance;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final orders = await db.orders
        .filter()
        .driverIdEqualTo(driverId)
        .and()
        .deliveryDateGreaterThan(startOfDay)
        .findAll();

    return OrderStats(
      total: orders.length,
      completed: orders.where((o) => o.status == 'delivered').length,
      pending: orders.where((o) => o.status != 'delivered').length,
      inTransit: orders.where((o) => o.status == 'in_transit').length,
    );
  }

  /// Get orders that need sync
  Future<List<OrderEntity>> getUnsyncedOrders() async {
    final db = await IsarDatabase.instance;
    return await db.orders
        .filter()
        .syncStatus((q) => q.hasPendingChangesEqualTo(true))
        .or()
        .syncStatusIsNull()
        .findAll();
  }

  /// Watch orders for real-time updates
  Stream<List<OrderEntity>> watchOrders(String driverId) async* {
    final db = await IsarDatabase.instance;

    yield* db.orders
        .filter()
        .driverIdEqualTo(driverId)
        .sortByDeliveryDate()
        .watch(fireImmediately: true);
  }

  /// Clear old completed orders (keep last 30 days)
  Future<int> cleanupOldOrders() async {
    final db = await IsarDatabase.instance;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final oldOrders = await db.orders
        .filter()
        .statusEqualTo('delivered')
        .and()
        .deliveredAtIsNotNull()
        .and()
        .deliveredAtLessThan(cutoff)
        .findAll();

    await db.writeTxn(() async {
      for (final order in oldOrders) {
        await db.orders.delete(order.id);
      }
    });

    return oldOrders.length;
  }

  /// Helper: Find order by ID (local or server)
  Future<OrderEntity?> _findOrder(Isar db, String orderId) async {
    // Try by local ID
    if (int.tryParse(orderId) != null) {
      final localId = int.parse(orderId);
      final byLocalId = await db.orders.get(localId);
      if (byLocalId != null) return byLocalId;
    }

    // Try by server ID
    final byServerId =
        await db.orders.filter().serverIdEqualTo(orderId).findFirst();
    if (byServerId != null) return byServerId;

    // Try by order code
    final byCode =
        await db.orders.filter().orderCodeEqualTo(orderId).findFirst();
    return byCode;
  }

  /// Helper: Queue order update for sync
  Future<void> _queueOrderUpdate(
    Isar db,
    OrderEntity order,
    String operation, {
    int priority = 2,
    bool syncImmediately = false,
  }) async {
    final queueItem = SyncQueueItem(
      entityType: 'order',
      localId: order.id.toString(),
      serverId: order.serverId,
      operation: operation,
      payload: jsonEncode(order.toJson()),
      priority: priority,
      syncImmediately: syncImmediately,
    );

    await db.syncQueue.put(queueItem);
  }
}

/// Order statistics
class OrderStats {
  final int total;
  final int completed;
  final int pending;
  final int inTransit;

  OrderStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.inTransit,
  });

  double get completionRate => total > 0 ? completed / total : 0;

  String get formattedCompletionRate =>
      '${(completionRate * 100).toStringAsFixed(0)}%';
}
