import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/blocs/sync/sync_bloc.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/services/database_service.dart';
import 'package:isar/isar.dart';
import 'package:mobile/db/schemas/sync_queue.dart';

import 'sync_bloc_test.mocks.dart';

@GenerateMocks([SyncService, DatabaseService, Connectivity, Isar])
void main() {
  group('SyncBloc', () {
    late MockSyncService mockSyncService;
    late MockDatabaseService mockDatabaseService;
    late MockConnectivity mockConnectivity;
    late MockIsar mockIsar;
    late SyncBloc syncBloc;

    setUp(() {
      mockSyncService = MockSyncService();
      mockDatabaseService = MockDatabaseService();
      mockConnectivity = MockConnectivity();
      mockIsar = MockIsar();

      when(mockDatabaseService.isar).thenReturn(mockIsar);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream<ConnectivityResult>.empty());

      syncBloc = SyncBloc(
        mockSyncService,
        mockDatabaseService,
        mockConnectivity,
      );
    });

    tearDown(() {
      syncBloc.close();
    });

    test('initial state is SyncInitial', () {
      expect(syncBloc.state, isA<SyncInitial>());
    });

    group('SyncStarted', () {
      blocTest<SyncBloc, SyncState>(
        'emits [SyncOnline] when started with connectivity',
        build: () {
          when(mockConnectivity.checkConnectivity())
              .thenAnswer((_) async => ConnectivityResult.wifi);
          when(mockIsar.syncQueues).thenReturn(MockSyncQueueCollection());
          when(mockIsar.syncQueues.where()).thenReturn(MockSyncQuery());
          when(mockIsar.syncQueues.where().findAll())
              .thenAnswer((_) async => []);
          return syncBloc;
        },
        act: (bloc) => bloc.add(SyncStarted()),
        expect: () => [
          isA<SyncOnline>(),
        ],
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncOffline] when started without connectivity',
        build: () {
          when(mockConnectivity.checkConnectivity())
              .thenAnswer((_) async => ConnectivityResult.none);
          when(mockIsar.syncQueues).thenReturn(MockSyncQueueCollection());
          when(mockIsar.syncQueues.where()).thenReturn(MockSyncQuery());
          when(mockIsar.syncQueues.where().findAll())
              .thenAnswer((_) async => []);
          return syncBloc;
        },
        act: (bloc) => bloc.add(SyncStarted()),
        expect: () => [
          isA<SyncOffline>(),
        ],
      );
    });

    group('ConnectivityChanged', () {
      blocTest<SyncBloc, SyncState>(
        'emits [SyncOnline] when connectivity restored',
        build: () {
          when(mockIsar.syncQueues).thenReturn(MockSyncQueueCollection());
          when(mockIsar.syncQueues.where()).thenReturn(MockSyncQuery());
          when(mockIsar.syncQueues.where().findAll())
              .thenAnswer((_) async => []);
          return syncBloc;
        },
        seed: () => SyncOffline(pendingItems: 2),
        act: (bloc) => bloc.add(ConnectivityChanged(true)),
        expect: () => [
          isA<SyncOnline>(),
        ],
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncOffline] when connectivity lost',
        build: () {
          when(mockIsar.syncQueues).thenReturn(MockSyncQueueCollection());
          when(mockIsar.syncQueues.where()).thenReturn(MockSyncQuery());
          when(mockIsar.syncQueues.where().findAll())
              .thenAnswer((_) async => []);
          return syncBloc;
        },
        seed: () => SyncOnline(),
        act: (bloc) => bloc.add(ConnectivityChanged(false)),
        expect: () => [
          isA<SyncOffline>(),
        ],
      );
    });

    group('SyncQueueUpdated', () {
      blocTest<SyncBloc, SyncState>(
        'updates pending items count in SyncOnline state',
        build: () => syncBloc,
        seed: () => SyncOnline(pendingItems: 0),
        act: (bloc) => bloc.add(SyncQueueUpdated(5)),
        expect: () => [
          isA<SyncOnline>().having((s) => s.pendingItems, 'pendingItems', 5),
        ],
      );

      blocTest<SyncBloc, SyncState>(
        'updates pending items count in SyncOffline state',
        build: () => syncBloc,
        seed: () => SyncOffline(pendingItems: 0),
        act: (bloc) => bloc.add(SyncQueueUpdated(3)),
        expect: () => [
          isA<SyncOffline>().having((s) => s.pendingItems, 'pendingItems', 3),
        ],
      );
    });
  });
}

// Mock classes for Isar collections
class MockSyncQueueCollection extends Mock implements IsarCollection<SyncQueue> {
  @override
  QueryBuilder<SyncQueue, SyncQueue, QWhere> where() {
    return MockSyncQuery();
  }
}

class MockSyncQuery extends Mock implements QueryBuilder<SyncQueue, SyncQueue, QWhere> {
  @override
  QueryBuilder<SyncQueue, SyncQueue, QAfterWhereClause> sortByCreatedAt() {
    return this as QueryBuilder<SyncQueue, SyncQueue, QAfterWhereClause>;
  }

  @override
  Future<List<SyncQueue>> findAll() async {
    return [];
  }
}
