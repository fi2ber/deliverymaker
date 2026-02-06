import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/db/schemas/product.dart';
import 'package:mobile/db/schemas/sync_queue.dart';
import 'package:mobile/db/schemas/stock.dart';

import 'sync_service_test.mocks.dart';

@GenerateMocks([ApiService, DatabaseService, Isar, IsarCollection, QueryBuilder])
void main() {
  group('SyncService', () {
    late MockApiService mockApiService;
    late MockDatabaseService mockDatabaseService;
    late MockIsar mockIsar;
    late SyncService syncService;

    setUp(() {
      mockApiService = MockApiService();
      mockDatabaseService = MockDatabaseService();
      mockIsar = MockIsar();

      when(mockDatabaseService.isar).thenReturn(mockIsar);

      syncService = SyncService(mockApiService, mockDatabaseService);
    });

    group('pullData', () {
      test('should fetch and store products successfully', () async {
        // Arrange
        final productsData = [
          {
            'id': 'prod-1',
            'name': 'Test Product 1',
            'sku': 'SKU001',
            'basePrice': 100.0,
            'unit': 'PCS',
          },
          {
            'id': 'prod-2',
            'name': 'Test Product 2',
            'sku': 'SKU002',
            'basePrice': 200.0,
            'unit': 'KG',
          },
        ];

        final mockResponse = Response(
          data: productsData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/products'),
        );

        when(mockApiService.get('/products'))
            .thenAnswer((_) async => mockResponse);
        when(mockIsar.writeTxn(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          await callback();
        });
        when(mockIsar.products).thenReturn(MockIsarCollection<Product>());
        when(mockIsar.products.clear()).thenAnswer((_) async => 0);
        when(mockIsar.products.put(any)).thenAnswer((_) async => 1);

        // Act
        await syncService.pullData();

        // Assert
        verify(mockApiService.get('/products')).called(1);
        verify(mockIsar.products.clear()).called(1);
        verify(mockIsar.products.put(any)).called(2);
      });

      test('should throw error when API fails', () async {
        // Arrange
        when(mockApiService.get('/products'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/products'),
              error: 'Network error',
            ));

        // Act & Assert
        expect(() => syncService.pullData(), throwsA(isA<DioException>()));
      });
    });

    group('pullTruckStock', () {
      test('should fetch and store truck stock successfully', () async {
        // Arrange
        final warehouseData = {'id': 'wh-1', 'name': 'Truck 1'};
        final stockData = [
          {
            'product': {'id': 'prod-1', 'name': 'Product 1', 'basePrice': 100.0},
            'quantity': 50.0,
            'batch': {'batchCode': 'B001', 'expirationDate': '2025-12-31'},
          },
        ];

        final warehouseResponse = Response(
          data: warehouseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/warehouse/my'),
        );
        final stockResponse = Response(
          data: stockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/warehouse/wh-1/stock'),
        );

        when(mockApiService.get('/warehouse/my'))
            .thenAnswer((_) async => warehouseResponse);
        when(mockApiService.get('/warehouse/wh-1/stock'))
            .thenAnswer((_) async => stockResponse);
        when(mockIsar.writeTxn(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          await callback();
        });
        when(mockIsar.stocks).thenReturn(MockIsarCollection<Stock>());
        when(mockIsar.stocks.clear()).thenAnswer((_) async => 0);
        when(mockIsar.stocks.put(any)).thenAnswer((_) async => 1);

        // Act
        await syncService.pullTruckStock();

        // Assert
        verify(mockApiService.get('/warehouse/my')).called(1);
        verify(mockApiService.get('/warehouse/wh-1/stock')).called(1);
        verify(mockIsar.stocks.clear()).called(1);
        verify(mockIsar.stocks.put(any)).called(1);
      });

      test('should return early when no warehouse assigned', () async {
        // Arrange
        final warehouseResponse = Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/warehouse/my'),
        );

        when(mockApiService.get('/warehouse/my'))
            .thenAnswer((_) async => warehouseResponse);

        // Act
        await syncService.pullTruckStock();

        // Assert
        verify(mockApiService.get('/warehouse/my')).called(1);
        verifyNever(mockApiService.get(any));
      });
    });

    group('pushData', () {
      test('should process and remove successfully synced items', () async {
        // Arrange
        final queueItem = SyncQueue()
          ..id = 1
          ..action = SyncAction.create
          ..entityType = EntityType.order
          ..payload = '{"isVanSale": true, "clientId": "client-1", "items": []}'
          ..createdAt = DateTime.now();

        final mockCollection = MockIsarCollection<SyncQueue>();
        final mockQuery = MockQueryBuilder<SyncQueue, SyncQueue, QWhere>();

        when(mockIsar.syncQueues).thenReturn(mockCollection);
        when(mockCollection.where()).thenReturn(mockQuery);
        when(mockQuery.sortByCreatedAt()).thenReturn(mockQuery as QueryBuilder<SyncQueue, SyncQueue, QAfterWhereClause>);
        when(mockQuery.findAll()).thenAnswer((_) async => [queueItem]);
        when(mockApiService.post('/orders/van-sale', any))
            .thenAnswer((_) async => Response(
              data: {'id': 'order-1'},
              statusCode: 201,
              requestOptions: RequestOptions(path: '/orders/van-sale'),
            ));
        when(mockIsar.writeTxn(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          await callback();
        });
        when(mockCollection.delete(1)).thenAnswer((_) async => true);

        // Act
        await syncService.pushData();

        // Assert
        verify(mockApiService.post('/orders/van-sale', any)).called(1);
        verify(mockCollection.delete(1)).called(1);
      });

      test('should handle failed sync items gracefully', () async {
        // Arrange
        final queueItem = SyncQueue()
          ..id = 1
          ..action = SyncAction.create
          ..entityType = EntityType.order
          ..payload = '{"isVanSale": true, "clientId": "client-1", "items": []}'
          ..createdAt = DateTime.now();

        final mockCollection = MockIsarCollection<SyncQueue>();
        final mockQuery = MockQueryBuilder<SyncQueue, SyncQueue, QWhere>();

        when(mockIsar.syncQueues).thenReturn(mockCollection);
        when(mockCollection.where()).thenReturn(mockQuery);
        when(mockQuery.sortByCreatedAt()).thenReturn(mockQuery as QueryBuilder<SyncQueue, SyncQueue, QAfterWhereClause>);
        when(mockQuery.findAll()).thenAnswer((_) async => [queueItem]);
        when(mockApiService.post('/orders/van-sale', any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/orders/van-sale'),
              error: 'Server error',
            ));

        // Act - should not throw
        await syncService.pushData();

        // Assert - item should not be deleted on failure
        verifyNever(mockCollection.delete(any));
      });
    });

    group('queueVanSale', () {
      test('should add van sale to sync queue', () async {
        // Arrange
        final items = [
          {'productId': 'prod-1', 'quantity': 2, 'price': 100.0},
        ];

        final mockCollection = MockIsarCollection<SyncQueue>();
        when(mockIsar.syncQueues).thenReturn(mockCollection);
        when(mockIsar.writeTxn(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          await callback();
        });
        when(mockCollection.put(any)).thenAnswer((_) async => 1);

        // Act
        await syncService.queueVanSale('client-1', items);

        // Assert
        verify(mockIsar.writeTxn(any)).called(1);
        verify(mockCollection.put(any)).called(1);
      });
    });

    group('queueDelivery', () {
      test('should add delivery update to sync queue', () async {
        // Arrange
        final mockOrder = MockOrder();
        when(mockOrder.remoteId).thenReturn('order-1');
        when(mockOrder.status).thenReturn('DELIVERED');
        when(mockOrder.totalAmount).thenReturn(500.0);
        when(mockOrder.paymentInfo).thenReturn('CASH');
        when(mockOrder.items).thenReturn([]);

        final mockCollection = MockIsarCollection<SyncQueue>();
        when(mockIsar.syncQueues).thenReturn(mockCollection);
        when(mockIsar.writeTxn(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          await callback();
        });
        when(mockCollection.put(any)).thenAnswer((_) async => 1);

        // Act
        await syncService.queueDelivery(mockOrder);

        // Assert
        verify(mockIsar.writeTxn(any)).called(1);
        verify(mockCollection.put(any)).called(1);
      });
    });
  });
}

// Mock classes
class MockOrder extends Mock implements dynamic {
  String? remoteId;
  String? status;
  double? totalAmount;
  String? paymentInfo;
  List<dynamic> items = [];
}
