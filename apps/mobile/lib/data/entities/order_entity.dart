import 'package:isar/isar.dart';
import 'sync_queue_item.dart';

part 'order_entity.g.dart';

/// Local representation of Order for Isar database
/// Supports offline-first operations
@Collection()
class OrderEntity {
  /// Local ID (UUID generated on device)
  Id id = Isar.autoIncrement;

  /// Server-side ID (null until synced)
  @Index(unique: true)
  String? serverId;

  /// Order code (e.g., "SUB-240215-A3F7-D1")
  @Index()
  late String orderCode;

  /// Subscription ID this order belongs to
  @Index()
  String? subscriptionId;

  /// Customer info (denormalized for offline access)
  late String customerName;
  late String customerPhone;
  String? customerTelegramId;

  /// Delivery address
  late String address;
  String? addressComment;
  double? latitude;
  double? longitude;

  /// Order status
  /// pending, confirmed, packing, ready, assigned, in_transit, delivered, cancelled
  @Index()
  late String status;

  /// Order source
  late String source; // subscription, manual

  /// Items to deliver
  List<OrderItem> items = [];

  /// Total amount
  double totalAmount = 0;

  /// Delivery date
  @Index()
  late DateTime deliveryDate;

  /// Assigned driver
  String? driverId;
  String? driverName;
  String? driverPhone;

  /// Timestamps
  DateTime? assignedAt;
  DateTime? pickedUpAt;
  DateTime? deliveredAt;

  /// Delivery proof (photo path, signature, notes)
  DeliveryProof? deliveryProof;

  /// Sync status
  SyncStatus? syncStatus;

  /// Local creation timestamp
  late DateTime createdAt;

  /// Last local update
  @Index()
  late DateTime updatedAt;

  /// Version for optimistic locking
  int version = 1;

  /// Whether this order is completed locally
  bool get isCompletedLocally =>
      status == 'delivered' && deliveryProof != null;

  /// Whether this order needs sync
  bool get needsSync =>
      syncStatus == null ||
      !syncStatus!.isSynced ||
      syncStatus!.hasPendingChanges;

  OrderEntity({
    required this.orderCode,
    this.serverId,
    this.subscriptionId,
    required this.customerName,
    required this.customerPhone,
    this.customerTelegramId,
    required this.address,
    this.addressComment,
    this.latitude,
    this.longitude,
    this.status = 'pending',
    this.source = 'subscription',
    this.items = const [],
    this.totalAmount = 0,
    required this.deliveryDate,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryProof,
    this.syncStatus,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    syncStatus ??= SyncStatus();
  }

  void markAsDelivered(DeliveryProof proof) {
    status = 'delivered';
    deliveredAt = DateTime.now();
    deliveryProof = proof;
    syncStatus ??= SyncStatus();
    syncStatus!.hasPendingChanges = true;
    updatedAt = DateTime.now();
    version++;
  }

  void markAsPickedUp() {
    status = 'in_transit';
    pickedUpAt = DateTime.now();
    syncStatus ??= SyncStatus();
    syncStatus!.hasPendingChanges = true;
    updatedAt = DateTime.now();
    version++;
  }

  Map<String, dynamic> toJson() => {
        'id': serverId,
        'orderCode': orderCode,
        'subscriptionId': subscriptionId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address,
        'status': status,
        'totalAmount': totalAmount,
        'deliveryDate': deliveryDate.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'deliveryProof': deliveryProof?.toJson(),
        'version': version,
      };
}

@embedded
class OrderItem {
  late String productId;
  String? productName;
  late double quantity;
  String? unit;
  double? price;

  OrderItem({
    required this.productId,
    this.productName,
    required this.quantity,
    this.unit,
    this.price,
  });
}

@embedded
class DeliveryProof {
  /// Local photo file path
  late String photoPath;

  /// Optional signature (base64 or path)
  String? signaturePath;

  /// Notes from driver
  String? notes;

  /// When delivery was marked
  late DateTime timestamp;

  /// Whether photo was uploaded to server
  bool photoUploaded = false;

  DeliveryProof({
    required this.photoPath,
    this.signaturePath,
    this.notes,
    DateTime? timestamp,
    this.photoUploaded = false,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'photoPath': photoPath,
        'signaturePath': signaturePath,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };
}
