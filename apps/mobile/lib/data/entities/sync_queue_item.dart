import 'package:isar/isar.dart';

part 'sync_queue_item.g.dart';

/// Represents an item in the sync queue
/// Tracks pending changes that need to be synced to server
@Collection()
class SyncQueueItem {
  Id id = Isar.autoIncrement;

  /// Entity type: 'order', 'delivery_proof', 'location_update'
  @Index()
  late String entityType;

  /// Local entity ID (e.g., order ID)
  @Index()
  late String localId;

  /// Server entity ID (null if not synced yet)
  String? serverId;

  /// Operation type: 'create', 'update', 'delete'
  @Index()
  late String operation;

  /// JSON payload with entity data
  late String payload;

  /// Timestamp when item was queued
  @Index()
  late DateTime createdAt;

  /// Number of sync attempts
  int retryCount = 0;

  /// Last error message (if any)
  String? lastError;

  /// Last sync attempt timestamp
  DateTime? lastAttemptAt;

  /// Priority: 1 = high, 2 = normal, 3 = low
  /// Delivery proofs are high priority
  @Index()
  int priority = 2;

  /// Whether this item should be processed immediately when online
  bool syncImmediately = false;

  SyncQueueItem({
    required this.entityType,
    required this.localId,
    this.serverId,
    required this.operation,
    required this.payload,
    this.priority = 2,
    this.syncImmediately = false,
  }) {
    createdAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'localId': localId,
        'serverId': serverId,
        'operation': operation,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'priority': priority,
      };
}

/// Sync status for entities
@embedded
class SyncStatus {
  /// Whether entity is synced with server
  bool isSynced = false;

  /// Last sync timestamp
  DateTime? syncedAt;

  /// Server entity ID
  String? serverId;

  /// Pending changes (not synced yet)
  bool hasPendingChanges = false;

  /// Conflict detected flag
  bool hasConflict = false;

  SyncStatus({
    this.isSynced = false,
    this.syncedAt,
    this.serverId,
    this.hasPendingChanges = false,
    this.hasConflict = false,
  });
}
