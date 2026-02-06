import 'package:isar/isar.dart';

part 'sync_queue.g.dart';

enum SyncAction { create, update, delete }
enum EntityType { order, customer, product }

@collection
class SyncQueue {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  late SyncAction action;

  @Enumerated(EnumType.ordinal)
  late EntityType entityType;

  late String payload; // JSON payload

  late DateTime createdAt;

  int retryCount = 0;
}
