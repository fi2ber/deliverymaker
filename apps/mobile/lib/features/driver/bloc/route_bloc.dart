import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../data/entities/order_entity.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../services/map_service.dart';

// Events
abstract class RouteEvent extends Equatable {
  const RouteEvent();
  @override
  List<Object?> get props => [];
}

class LoadRoute extends RouteEvent {
  final String driverId;
  final DateTime? date;
  const LoadRoute(this.driverId, {this.date});
  @override
  List<Object?> get props => [driverId, date];
}

class RefreshRoute extends RouteEvent {
  const RefreshRoute();
}

class UpdateCurrentLocation extends RouteEvent {
  final LatLng location;
  const UpdateCurrentLocation(this.location);
  @override
  List<Object?> get props => [location];
}

class MarkStopCompleted extends RouteEvent {
  final String stopId;
  final DeliveryProof proof;
  const MarkStopCompleted(this.stopId, this.proof);
  @override
  List<Object?> get props => [stopId, proof];
}

class MarkStopPickedUp extends RouteEvent {
  final String stopId;
  const MarkStopPickedUp(this.stopId);
  @override
  List<Object?> get props => [stopId];
}

class RecenterMap extends RouteEvent {
  const RecenterMap();
}

class SyncStatusChanged extends RouteEvent {
  final SyncStatus status;
  const SyncStatusChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class ConnectionChanged extends RouteEvent {
  final bool isOnline;
  const ConnectionChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

// State
class RouteState extends Equatable {
  final List<OrderEntity> orders;
  final List<LatLng> routeGeometry;
  final RouteResult? routeInfo;
  final LatLng? currentLocation;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final SyncStatus syncStatus;
  final bool isOnline;
  final int completedStops;
  final bool needsRecenter;
  final OrderStats? stats;

  const RouteState({
    this.orders = const [],
    this.routeGeometry = const [],
    this.routeInfo,
    this.currentLocation,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.syncStatus = SyncStatus.idle,
    this.isOnline = true,
    this.completedStops = 0,
    this.needsRecenter = false,
    this.stats,
  });

  RouteState copyWith({
    List<OrderEntity>? orders,
    List<LatLng>? routeGeometry,
    RouteResult? routeInfo,
    LatLng? currentLocation,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    SyncStatus? syncStatus,
    bool? isOnline,
    int? completedStops,
    bool? needsRecenter,
    OrderStats? stats,
  }) {
    return RouteState(
      orders: orders ?? this.orders,
      routeGeometry: routeGeometry ?? this.routeGeometry,
      routeInfo: routeInfo ?? this.routeInfo,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      syncStatus: syncStatus ?? this.syncStatus,
      isOnline: isOnline ?? this.isOnline,
      completedStops: completedStops ?? this.completedStops,
      needsRecenter: needsRecenter ?? this.needsRecenter,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        orders,
        routeGeometry,
        routeInfo,
        currentLocation,
        isLoading,
        isRefreshing,
        error,
        syncStatus,
        isOnline,
        completedStops,
        needsRecenter,
        stats,
      ];

  // Helper getters
  List<OrderEntity> get pendingOrders =>
      orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();

  List<OrderEntity> get completedOrders =>
      orders.where((o) => o.status == 'delivered').toList();

  OrderEntity? get nextOrder => pendingOrders.isNotEmpty ? pendingOrders.first : null;

  double get progress => orders.isEmpty ? 0 : completedOrders.length / orders.length;
}

// BLoC
class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final OrderRepository _orderRepository = OrderRepository();
  final SyncEngine _syncEngine = SyncEngine();
  final ConnectivityService _connectivity = ConnectivityService();

  late final _syncSubscription;
  late final _connectivitySubscription;

  String? _currentDriverId;
  DateTime? _currentDate;

  RouteBloc() : super(const RouteState()) {
    _setupSubscriptions();
    _registerHandlers();
  }

  void _setupSubscriptions() {
    // Listen to sync status changes
    _syncSubscription = _syncEngine.syncStatus.listen((status) {
      add(SyncStatusChanged(status));
    });

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.isOnlineStream.listen((online) {
      add(ConnectionChanged(online));
    });
  }

  void _registerHandlers() {
    on<LoadRoute>(_onLoadRoute);
    on<RefreshRoute>(_onRefreshRoute);
    on<UpdateCurrentLocation>(_onUpdateLocation);
    on<MarkStopCompleted>(_onMarkCompleted);
    on<MarkStopPickedUp>(_onMarkPickedUp);
    on<RecenterMap>(_onRecenter);
    on<SyncStatusChanged>(_onSyncStatusChanged);
    on<ConnectionChanged>(_onConnectionChanged);
  }

  Future<void> _onLoadRoute(LoadRoute event, Emitter<RouteState> emit) async {
    _currentDriverId = event.driverId;
    _currentDate = event.date;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Load orders from local DB (works offline!)
      final orders = await _orderRepository.getDriverOrders(
        event.driverId,
        date: event.date,
      );

      // Get stats
      final stats = await _orderRepository.getTodayStats(event.driverId);

      // Calculate completed count
      final completed = orders.where((o) => o.status == 'delivered').length;

      emit(state.copyWith(
        orders: orders,
        completedStops: completed,
        stats: stats,
        isLoading: false,
      ));

      // Calculate route geometry if we have orders
      if (orders.isNotEmpty) {
        add(const RefreshRoute());
      }

      // Trigger background sync if online
      if (_connectivity.isOnline) {
        _syncEngine.sync();
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить маршрут: $e',
      ));
    }
  }

  Future<void> _onRefreshRoute(RefreshRoute event, Emitter<RouteState> emit) async {
    if (state.orders.isEmpty) return;

    emit(state.copyWith(isRefreshing: true));

    try {
      // Build route points: current location + order addresses
      final points = [
        if (state.currentLocation != null) state.currentLocation!,
        ...state.pendingOrders.map((o) {
          if (o.latitude != null && o.longitude != null) {
            return LatLng(o.latitude!, o.longitude!);
          }
          // Fallback to default if no coordinates
          return const LatLng(41.2995, 69.2401);
        }),
      ];

      if (points.length >= 2) {
        final route = await OSRMService.getRoute(points);

        emit(state.copyWith(
          routeGeometry: route.geometry,
          routeInfo: route,
          isRefreshing: false,
          needsRecenter: true,
        ));
      } else {
        emit(state.copyWith(isRefreshing: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        error: 'Не удалось построить маршрут: $e',
      ));
    }
  }

  void _onUpdateLocation(UpdateCurrentLocation event, Emitter<RouteState> emit) {
    emit(state.copyWith(currentLocation: event.location));
  }

  Future<void> _onMarkCompleted(MarkStopCompleted event, Emitter<RouteState> emit) async {
    try {
      // Save locally first (works offline!)
      await _orderRepository.markAsDelivered(
        event.stopId,
        event.proof,
      );

      // Reload orders
      if (_currentDriverId != null) {
        add(LoadRoute(_currentDriverId!, date: _currentDate));
      }

      // Trigger immediate sync
      _syncEngine.sync();
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка сохранения: $e'));
    }
  }

  Future<void> _onMarkPickedUp(MarkStopPickedUp event, Emitter<RouteState> emit) async {
    try {
      await _orderRepository.markAsPickedUp(event.stopId);

      // Reload orders
      if (_currentDriverId != null) {
        add(LoadRoute(_currentDriverId!, date: _currentDate));
      }

      _syncEngine.sync();
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка: $e'));
    }
  }

  void _onRecenter(RecenterMap event, Emitter<RouteState> emit) {
    emit(state.copyWith(needsRecenter: true));
    Future.delayed(const Duration(milliseconds: 100), () {
      emit(state.copyWith(needsRecenter: false));
    });
  }

  void _onSyncStatusChanged(SyncStatusChanged event, Emitter<RouteState> emit) {
    emit(state.copyWith(syncStatus: event.status));
  }

  void _onConnectionChanged(ConnectionChanged event, Emitter<RouteState> emit) {
    emit(state.copyWith(isOnline: event.isOnline));

    // If back online, trigger sync
    if (event.isOnline && !state.isOnline) {
      _syncEngine.sync();
    }
  }

  @override
  Future<void> close() {
    _syncSubscription.cancel();
    _connectivitySubscription.cancel();
    return super.close();
  }
}
