import 'package:isar/isar.dart';
import 'sync_queue_item.dart';

part 'product_entity.g.dart';

/// Product entity for local storage
/// Supports offline catalog browsing
@Collection()
class ProductEntity {
  Id id = Isar.autoIncrement;

  /// Server product ID
  @Index(unique: true)
  String? serverId;

  /// Product SKU/code
  @Index()
  late String sku;

  /// Product name
  late String name;

  /// Description
  String? description;

  /// Price in soms
  late double price;

  /// Discounted price (if any)
  double? discountedPrice;

  /// Unit (kg, piece, box, etc.)
  late String unit;

  /// Category
  @Index()
  String? categoryId;
  String? categoryName;

  /// Images (local paths or URLs)
  List<String> images = [];

  /// Stock availability
  bool inStock = true;
  double? stockQuantity;

  /// Is active (can be ordered)
  bool isActive = true;

  /// Display order
  int sortOrder = 0;

  /// Sync status
  SyncStatus? syncStatus;

  /// Last updated from server
  DateTime? serverUpdatedAt;

  /// Local timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  ProductEntity({
    required this.sku,
    required this.name,
    this.description,
    required this.price,
    this.discountedPrice,
    required this.unit,
    this.categoryId,
    this.categoryName,
    this.images = const [],
    this.inStock = true,
    this.stockQuantity,
    this.isActive = true,
    this.sortOrder = 0,
    this.syncStatus,
    this.serverUpdatedAt,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    syncStatus ??= SyncStatus();
  }

  /// Current price (discounted if available)
  double get currentPrice => discountedPrice ?? price;

  /// Has discount
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  /// Discount percentage
  int? get discountPercent {
    if (!hasDiscount) return null;
    return ((1 - discountedPrice! / price) * 100).round();
  }

  /// Main image (first or placeholder)
  String? get mainImage => images.isNotEmpty ? images.first : null;

  Map<String, dynamic> toJson() => {
        'id': serverId,
        'sku': sku,
        'name': name,
        'description': description,
        'price': price,
        'discountedPrice': discountedPrice,
        'unit': unit,
        'categoryId': categoryId,
        'inStock': inStock,
        'stockQuantity': stockQuantity,
        'isActive': isActive,
      };

  ProductEntity copyWith({
    String? name,
    String? description,
    double? price,
    double? discountedPrice,
    bool? inStock,
    double? stockQuantity,
    bool? isActive,
  }) {
    final copy = ProductEntity(
      sku: sku,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      unit: unit,
      categoryId: categoryId,
      categoryName: categoryName,
      images: images,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder,
      syncStatus: syncStatus,
    );
    copy.id = id;
    copy.serverId = serverId;
    copy.createdAt = createdAt;
    copy.updatedAt = DateTime.now();
    return copy;
  }
}

/// Product category
@Collection()
class ProductCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? serverId;

  late String name;
  String? description;
  String? imageUrl;
  int sortOrder = 0;
  bool isActive = true;

  ProductCategory({
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });
}

/// Cart item (for quick orders)
@embedded
class CartItem {
  late String productId;
  late String productName;
  late double price;
  late double quantity;
  late String unit;
  String? imageUrl;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrl,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'total': total,
      };
}
