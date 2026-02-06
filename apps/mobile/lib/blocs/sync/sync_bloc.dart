import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import '../../db/schemas/sync_queue.dart';
import '../../services/sync_service.dart';
import '../../services/database_service.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncStarted extends SyncEvent {}

class SyncRequested extends SyncEvent {}

class ConnectivityChanged extends SyncEvent {
  final bool isOnline;

  const ConnectivityChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

class SyncQueueUpdated extends SyncEvent {
  final int pendingCount;

  const SyncQueueUpdated(this.pendingCount);

  @override
  List<Object?> get props => [pendingCount];
}

// States
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncLoading extends SyncState {}

class SyncOnline extends SyncState {
  final bool isSyncing;
  final int pendingItems;
  final String? lastSyncTime;

  const SyncOnline({
    this.isSyncing = false,
    this.pendingItems = 0,
    this.lastSyncTime,
  });

  @override
  List<Object?> get props => [isSyncing, pendingItems, lastSyncTime];

  SyncOnline copyWith({
    bool? isSyncing,
    int? pendingItems,
    String? lastSyncTime,
  }) {
    return SyncOnline(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingItems: pendingItems ?? this.pendingItems,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncOffline extends SyncState {
  final int pendingItems;

  const SyncOffline({this.pendingItems = 0});

  @override
  List<Object?> get props => [pendingItems];

  SyncOffline copyWith({int? pendingItems}) {
    return SyncOffline(pendingItems: pendingItems ?? this.pendingItems);
  }
}

class SyncFailure extends SyncState {
  final String message;

  const SyncFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  final DatabaseService _databaseService;
  final Connectivity _connectivity;

  SyncBloc(
    this._syncService,
    this._databaseService,
    this._connectivity,
  ) : super(SyncInitial()) {
    on<SyncStarted>(_onSyncStarted);
    on<SyncRequested>(_onSyncRequested);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<SyncQueueUpdated>(_onSyncQueueUpdated);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      add(ConnectivityChanged(isOnline));
    });
  }

  Future<void> _onSyncStarted(
    SyncStarted event,
    Emitter<SyncState> emit,
  ) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    final pendingCount = await _getPendingCount();

    if (isOnline) {
      emit(SyncOnline(pendingItems: pendingCount));
      // Auto-sync on start if online
      add(SyncRequested());
    } else {
      emit(SyncOffline(pendingItems: pendingCount));
    }
  }

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (state is! SyncOnline) return;

    final currentState = state as SyncOnline;
    emit(currentState.copyWith(isSyncing: true));

    try {
      // Push pending changes first
      await _syncService.pushData();
      // Then pull fresh data
      await _syncService.pullData();
      await _syncService.pullTruckStock();

      final pendingCount = await _getPendingCount();
      emit(SyncOnline(
        isSyncing: false,
        pendingItems: pendingCount,
        lastSyncTime: DateTime.now().toIso8601String(),
      ));
    } catch (e) {
      emit(currentState.copyWith(isSyncing: false));
      // Don't emit failure, just stop syncing
    }
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    final pendingCount = await _getPendingCount();

    if (event.isOnline) {
      emit(SyncOnline(pendingItems: pendingCount));
      // Auto-sync when coming back online
      add(SyncRequested());
    } else {
      emit(SyncOffline(pendingItems: pendingCount));
    }
  }

  Future<void> _onSyncQueueUpdated(
    SyncQueueUpdated event,
    Emitter<SyncState> emit,
  ) async {
    if (state is SyncOnline) {
      emit((state as SyncOnline).copyWith(pendingItems: event.pendingCount));
    } else if (state is SyncOffline) {
      emit((state as SyncOffline).copyWith(pendingItems: event.pendingCount));
    }
  }

  Future<int> _getPendingCount() async {
    final queue = await _databaseService.isar.syncQueues.where().findAll();
    return queue.length;
  }
}
