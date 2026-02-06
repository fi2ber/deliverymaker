import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();

  Stream<bool> get connectionChange => _connectionChangeController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (wasOnline != _isOnline) {
      _connectionChangeController.add(_isOnline);
    }
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
