import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
/// Provides streams and helpers for online/offline detection
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectionStatus>.broadcast();
  final _simpleController = StreamController<bool>.broadcast();

  ConnectionStatus _lastStatus = ConnectionStatus.unknown;
  Timer? _periodicCheckTimer;

  /// Stream of detailed connection status changes
  Stream<ConnectionStatus> get statusStream => _controller.stream;

  /// Simple stream: true = online, false = offline
  Stream<bool> get isOnlineStream => _simpleController.stream;

  /// Current connection status
  ConnectionStatus get currentStatus => _lastStatus;

  /// Whether currently online
  bool get isOnline =>
      _lastStatus == ConnectionStatus.wifi ||
      _lastStatus == ConnectionStatus.mobile;

  /// Whether currently offline
  bool get isOffline => _lastStatus == ConnectionStatus.offline;

  /// Whether on WiFi
  bool get isWifi => _lastStatus == ConnectionStatus.wifi;

  /// Whether on mobile data
  bool get isMobile => _lastStatus == ConnectionStatus.mobile;

  /// Initialize service
  Future<void> initialize() async {
    // Get initial status
    await _checkConnectivity();

    // Listen to changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Start periodic checks (every 30 seconds)
    _startPeriodicChecks();
  }

  /// Dispose resources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _controller.close();
    _simpleController.close();
  }

  /// Check current connectivity
  Future<bool> checkNow() async {
    await _checkConnectivity();
    return isOnline;
  }

  /// Wait until online (with timeout)
  Future<bool> waitForOnline({Duration timeout = const Duration(minutes: 2)}) async {
    if (isOnline) return true;

    final completer = Completer<bool>();
    StreamSubscription? sub;

    sub = isOnlineStream.listen((online) {
      if (online && !completer.isCompleted) {
        completer.complete(true);
        sub?.cancel();
      }
    });

    // Timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
        sub?.cancel();
      }
    });

    return completer.future;
  }

  /// Start periodic connectivity checks
  void _startPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    _updateStatus(_mapResult(result));
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(_mapResult(result));
    } catch (e) {
      _updateStatus(ConnectionStatus.offline);
    }
  }

  /// Map ConnectivityResult to ConnectionStatus
  ConnectionStatus _mapResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionStatus.wifi;
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return ConnectionStatus.mobile;
      case ConnectivityResult.none:
        return ConnectionStatus.offline;
      default:
        return ConnectionStatus.unknown;
    }
  }

  /// Update status and notify listeners
  void _updateStatus(ConnectionStatus status) {
    if (_lastStatus != status) {
      _lastStatus = status;
      _controller.add(status);
      _simpleController.add(isOnline);
    }
  }
}

/// Connection status enum
enum ConnectionStatus {
  wifi,
  mobile,
  offline,
  unknown,
}

extension ConnectionStatusExtension on ConnectionStatus {
  bool get isOnline => this == ConnectionStatus.wifi || this == ConnectionStatus.mobile;
  bool get isOffline => this == ConnectionStatus.offline;
  bool get isWifi => this == ConnectionStatus.wifi;
  bool get isMobile => this == ConnectionStatus.mobile;

  String get displayName {
    switch (this) {
      case ConnectionStatus.wifi:
        return 'WiFi';
      case ConnectionStatus.mobile:
        return 'Мобильный интернет';
      case ConnectionStatus.offline:
        return 'Нет связи';
      case ConnectionStatus.unknown:
        return 'Проверка...';
    }
  }

  String get icon {
    switch (this) {
      case ConnectionStatus.wifi:
        return '📶';
      case ConnectionStatus.mobile:
        return '📱';
      case ConnectionStatus.offline:
        return '📵';
      case ConnectionStatus.unknown:
        return '⏳';
    }
  }
}
