import 'package:isar/isar.dart';
import '../../core/database/isar_database.dart';
import '../../core/sync/sync_engine.dart';
import '../entities/product_entity.dart';

/// Repository for Product operations
/// Handles offline catalog and sync
class ProductRepository {
  final _syncEngine = SyncEngine();

  /// Get products (from local DB - works offline)
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    bool inStockOnly = true,
  }) async {
    final db = await IsarDatabase.instance;

    var query = db.products.filter();

    if (categoryId != null) {
      query = query.categoryIdEqualTo(categoryId);
    }

    if (inStockOnly) {
      query = query.inStockEqualTo(true);
    }

    return await query
        .isActiveEqualTo(true)
        .sortBySortOrder()
        .thenByName()
        .findAll();
  }

  /// Get product by ID
  Future<ProductEntity?> getProductById(String productId) async {
    final db = await IsarDatabase.instance;

    // Try by server ID
    var product =
        await db.products.filter().serverIdEqualTo(productId).findFirst();

    // Try by local ID
    if (product == null && int.tryParse(productId) != null) {
      product = await db.products.get(int.parse(productId));
    }

    return product;
  }

  /// Search products
  Future<List<ProductEntity>> searchProducts(String query) async {
    final db = await IsarDatabase.instance;

    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return await db.products
        .filter()
        .nameContains(lowerQuery, caseSensitive: false)
        .or()
        .skuContains(lowerQuery, caseSensitive: false)
        .and()
        .isActiveEqualTo(true)
        .findAll();
  }

  /// Get all categories
  Future<List<ProductCategory>> getCategories() async {
    final db = await IsarDatabase.instance;
    return await db.productCategories
        .where()
        .isActiveEqualTo(true)
        .sortBySortOrder()
        .findAll();
  }

  /// Get category by ID
  Future<ProductCategory?> getCategoryById(String categoryId) async {
    final db = await IsarDatabase.instance;
    return await db.productCategories
        .filter()
        .serverIdEqualTo(categoryId)
        .findFirst();
  }

  /// Save products from server (after sync)
  Future<void> saveProductsFromServer(List<ProductEntity> products) async {
    final db = await IsarDatabase.instance;

    await db.writeTxn(() async {
      for (final product in products) {
        // Check if exists
        final existing = await db.products
            .filter()
            .serverIdEqualTo(product.serverId)
            .findFirst();

        if (existing != null) {
          // Update if newer
          final serverUpdated = product.serverUpdatedAt;
          final localUpdated = existing.serverUpdatedAt;

          if (serverUpdated != null &&
              (localUpdated == null || serverUpdated.isAfter(localUpdated))) {
            product.id = existing.id;
            product.syncStatus = SyncStatus()..isSynced = true;
            await db.products.put(product);
          }
        } else {
          // New product
          product.syncStatus = SyncStatus()..isSynced = true;
          await db.products.put(product);
        }
      }
    });
  }

  /// Sync products with server
  /// Call when online to get latest catalog
  Future<void> syncProducts() async {
    // TODO: Implement actual API call
    // For now, this is a placeholder
    
    // 1. Get last sync timestamp
    // 2. Call API: GET /products?updated_after={timestamp}
    // 3. Save returned products
    // 4. Update last sync timestamp
  }

  /// Get featured/popular products
  Future<List<ProductEntity>> getFeaturedProducts({int limit = 10}) async {
    final db = await IsarDatabase.instance;

    // For now, return first active products
    // In production, use actual popularity metrics
    return await db.products
        .where()
        .isActiveEqualTo(true)
        .and()
        .inStockEqualTo(true)
        .limit(limit)
        .findAll();
  }

  /// Get products with discount
  Future<List<ProductEntity>> getDiscountedProducts() async {
    final db = await IsarDatabase.instance;

    return await db.products
        .filter()
        .discountedPriceIsNotNull()
        .and()
        .isActiveEqualTo(true)
        .and()
        .inStockEqualTo(true)
        .findAll();
  }

  /// Update product (admin only)
  Future<void> updateProduct(ProductEntity product) async {
    final db = await IsarDatabase.instance;

    await db.writeTxn(() async {
      product.updatedAt = DateTime.now();
      product.syncStatus ??= SyncStatus();
      product.syncStatus!.hasPendingChanges = true;
      await db.products.put(product);
    });

    _syncEngine.sync();
  }

  /// Get total product count
  Future<int> getProductCount() async {
    final db = await IsarDatabase.instance;
    return await db.products.where().count();
  }

  /// Get catalog last updated timestamp
  Future<DateTime?> getLastCatalogUpdate() async {
    final db = await IsarDatabase.instance;

    final products = await db.products
        .where()
        .sortByServerUpdatedAtDesc()
        .limit(1)
        .findAll();

    return products.isNotEmpty ? products.first.serverUpdatedAt : null;
  }
}
