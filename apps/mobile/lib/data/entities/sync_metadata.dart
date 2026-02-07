import 'package:isar/isar.dart';

part 'sync_metadata.g.dart';

/// Stores sync metadata and app state
@Collection()
class SyncMetadata {
  Id id = 1; // Singleton, always 1

  /// Last successful full sync timestamp
  DateTime? lastFullSync;

  /// Last sync attempt timestamp
  DateTime? lastSyncAttempt;

  /// Whether initial sync completed
  bool initialSyncCompleted = false;

  /// Current sync session ID (if syncing)
  String? currentSyncSessionId;

  /// Total items synced (for stats)
  int totalItemsSynced = 0;

  /// Failed sync attempts count
  int failedSyncAttempts = 0;

  /// Whether app is in offline mode (forced)
  bool offlineMode = false;

  /// Server endpoint URL
  String? serverUrl;

  /// Auth token (encrypted in real app)
  String? authToken;

  /// Driver ID (current user)
  String? driverId;

  /// Driver role
  String? driverRole;

  /// Driver name
  String? driverName;

  /// Last known location (for recovery)
  double? lastLatitude;
  double? lastLongitude;
  DateTime? lastLocationUpdate;

  /// App version
  String? appVersion;

  /// Device ID
  String? deviceId;

  /// Settings
  bool autoSync = true;
  bool syncOnWifiOnly = false;
  bool backgroundSync = true;

  SyncMetadata();
}

/// Tracks which entities were modified and need sync
@Collection()
class PendingChange {
  Id id = Isar.autoIncrement;

  /// Entity collection name
  @Index()
  late String collection;

  /// Entity local ID
  @Index()
  late String entityId;

  /// Change type: create, update, delete
  @Index()
  late String changeType;

  /// When change was made
  @Index()
  late DateTime changedAt;

  /// JSON diff or full object
  late String changeData;

  PendingChange({
    required this.collection,
    required this.entityId,
    required this.changeType,
    required this.changeData,
  }) {
    changedAt = DateTime.now();
  }
}
