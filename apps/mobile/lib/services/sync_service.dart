import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:mobile/db/schemas/product.dart';
import 'package:mobile/db/schemas/sync_queue.dart';
import 'package:mobile/db/schemas/route.dart';
import 'package:mobile/db/schemas/stock.dart';
import 'package:mobile/db/schemas/order_item.dart';
import 'package:mobile/db/schemas/order.dart'; 
import 'api_service.dart';
import 'database_service.dart';

class SyncService {
  final ApiService _api;
  final DatabaseService _db;

  SyncService(this._api, this._db);

  /// Pulls latest data from server
  Future<void> pullData() async {
    try {
      // 1. Fetch Products
      final response = await _api.get('/products');
      final List<dynamic> productsJson = response.data;

      await _db.isar.writeTxn(() async {
        // Simple strategy: Clear and Replace (optimize later with "last_updated")
        await _db.isar.products.clear();

        for (var p in productsJson) {
          final product = Product()
            ..remoteId = p['id']
            ..name = p['name']
            ..sku = p['sku']
            ..price = double.tryParse(p['basePrice'].toString())
            ..unit = p['unit']
            ..updatedAt = DateTime.now(); // or parse from server
          
          await _db.isar.products.put(product);
        }
      });
      print("Synced ${productsJson.length} products");
    } catch (e) {
      print("Pull Error: $e");
      rethrow;
    }
  }
  
  /// Pulls stock for the driver's truck
  Future<void> pullTruckStock() async {
    try {
        // 1. Get My Warehouse ID
        final whResponse = await _api.get('/warehouse/my');
        final warehouse = whResponse.data;
        if (warehouse == null) return;
        
        final warehouseId = warehouse['id'];
        
        // 2. Get Stock
        final stockResponse = await _api.get('/warehouse/$warehouseId/stock');
        final List<dynamic> stockJson = stockResponse.data;
        
        await _db.isar.writeTxn(() async {
            await _db.isar.stocks.clear();
            
            for (var s in stockJson) {
                final stock = Stock()
                  ..productId = s['product']['id']
                  ..productName = s['product']['name']
                  ..quantity = double.tryParse(s['quantity'].toString()) ?? 0
                  ..price = double.tryParse(s['product']?['basePrice']?.toString() ?? '0') ?? 0
                  ..batchCode = s['batch']?['batchCode']
                  ..expirationDate = s['batch']?['expirationDate'] != null 
                      ? DateTime.parse(s['batch']['expirationDate']) 
                      : null;
                
                await _db.isar.stocks.put(stock);
            }
        });
        print("Synced Stock: ${stockJson.length} batches");
    } catch (e) {
        print("Stock Sync Error: $e");
    }
  }

  /// Pushes local changes to server
  Future<void> pushData() async {
    final queueItems = await _db.isar.syncQueues.where().sortByCreatedAt().findAll();

    for (var item in queueItems) {
      try {
        if (item.entityType == EntityType.order) {
            if (item.action == SyncAction.create) {
                await _processCreateOrder(item);
            } else if (item.action == SyncAction.update) {
                await _processUpdateOrder(item);
            }
        }
        
        // On success, delete from queue
        await _db.isar.writeTxn(() async {
          await _db.isar.syncQueues.delete(item.id);
        });

      } catch (e) {
        print("Push Error for item ${item.id}: $e");
        // Implement retry logic or backoff here
      }
    }
  }

  /// Queues a delivery action (update order status/items)
  Future<void> queueDelivery(Order order) async {
      await _db.isar.writeTxn(() async {
          final payload = jsonEncode({
              'orderId': order.remoteId,
              'action': 'delivery',
              'status': order.status,
              'actualTotal': order.totalAmount,
              'paymentMethod': order.paymentInfo,
              'items': order.items.map((i) => {
                  'productId': i.productId,
                  'delivered': i.deliveredQuantity,
                  'rejected': i.rejectedQuantity
              }).toList()
          });

          final item = SyncQueue()
             ..action = SyncAction.update
             ..entityType = EntityType.order
             ..payload = payload
             ..createdAt = DateTime.now();
          
          await _db.isar.syncQueues.put(item);
      });
      
      // Try push immediately if online
      pushData();
  }

  Future<void> _processCreateOrder(SyncQueue item) async {
    final payload = jsonDecode(item.payload);
    
    if (payload['isVanSale'] == true) {
         // Van Sale does not need remoteId mapping immediately as it's instant delivery
         await _api.post('/orders/van-sale', payload);
    } else {
        // Normal Order
        final response = await _api.post('/orders', payload);
        // final remoteId = response.data['id'];
        // Update local logic if needed
    }
  }

  Future<void> _processUpdateOrder(SyncQueue item) async {
      final payload = jsonDecode(item.payload);
      final action = payload['action'];
      
      if (action == 'delivery') {
          final orderId = payload['orderId'];
          if (orderId == null) return; 
          await _api.post('/logistics/orders/$orderId/delivery', payload);
      }
  }

  Future<void> queueVanSale(
    String clientId, 
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'CASH',
  }) async {
    final fullPayload = jsonEncode({
        'isVanSale': true,
        'clientId': clientId,
        'paymentMethod': paymentMethod,
        'items': items
    });

    final item = SyncQueue()
        ..action = SyncAction.create
        ..entityType = EntityType.order
        ..payload = fullPayload
        ..createdAt = DateTime.now();

    await _db.isar.writeTxn(() async {
         await _db.isar.syncQueues.put(item);
    });
    pushData();
  }
}
