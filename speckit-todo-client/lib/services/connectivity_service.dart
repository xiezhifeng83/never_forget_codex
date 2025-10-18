import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Broadcasts device connectivity status for offline queue coordination.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOnline = true;

  /// Emits true when the device reports a non-none connection.
  Stream<bool> get online$ => _onlineController.stream;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final initial = await _connectivity.checkConnectivity();
    _updateStatus(initial);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }

  void _updateStatus(ConnectivityResult result) {
    final next = result != ConnectivityResult.none;
    if (next != _isOnline) {
      _isOnline = next;
      _onlineController.add(_isOnline);
    }
  }
}
