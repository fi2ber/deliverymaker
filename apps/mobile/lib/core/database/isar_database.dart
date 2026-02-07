import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/entities/order_entity.dart';
import '../../data/entities/sync_queue_item.dart';
import '../../data/entities/sync_metadata.dart';

/// Central database service for Isar
/// Manages all local data access
class IsarDatabase {
  static Isar? _instance;

  /// Get singleton instance
  static Future<Isar> get instance async {
    _instance ??= await _init();
    return _instance!;
  }

  /// Initialize Isar
  static Future<Isar> _init() async {
    final dir = await getApplicationDocumentsDirectory();

    return await Isar.open(
      [
        OrderEntitySchema,
        SyncQueueItemSchema,
        SyncMetadataSchema,
        PendingChangeSchema,
      ],
      directory: dir.path,
      name: 'delivery_app',
      inspector: true, // Enable Isar Inspector for debugging
    );
  }

  /// Close database (call on app termination)
  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }

  /// Clear all data (for logout)
  static Future<void> clearAll() async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.clear();
    });
  }
}

/// Extension methods for common operations
extension IsarDatabaseExtensions on Isar {
  /// Orders collection helper
  IsarCollection<OrderEntity> get orders => collection<OrderEntity>();

  /// Sync queue helper
  IsarCollection<SyncQueueItem> get syncQueue => collection<SyncQueueItem>();

  /// Sync metadata helper
  IsarCollection<SyncMetadata> get syncMeta => collection<SyncMetadata>();

  /// Pending changes helper
  IsarCollection<PendingChange> get pendingChanges => collection<PendingChange>();
}

/// Database initialization helper
class DatabaseInitializer {
  /// Initialize database and perform migrations if needed
  static Future<void> initialize() async {
    final db = await IsarDatabase.instance;

    // Ensure metadata exists
    await db.writeTxn(() async {
      var meta = await db.syncMeta.get(1);
      if (meta == null) {
        meta = SyncMetadata()
          ..id = 1
          ..autoSync = true;
        await db.syncMeta.put(meta);
      }
    });

    // TODO: Run migrations if schema changed
  }

  /// Reset database (for debugging)
  static Future<void> reset() async {
    await IsarDatabase.close();
    final dir = await getApplicationDocumentsDirectory();
    final isarDir = Directory('${dir.path}/delivery_app.isar');
    if (await isarDir.exists()) {
      await isarDir.delete(recursive: true);
    }
    _instance = null;
  }
}
