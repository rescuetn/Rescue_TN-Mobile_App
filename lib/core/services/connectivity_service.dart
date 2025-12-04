import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  /// Check if device is currently connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  /// Check if device is currently connected to mobile data
  Future<bool> isConnectedToMobileData() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile);
    } catch (e) {
      return false;
    }
  }

  /// Listen to connectivity changes
  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged
        .map((List<ConnectivityResult> results) {
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    });
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
  }
}
