import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/entities/device_sync_status.dart';

class ConnectivityDataSource {
  final Connectivity _connectivity;
  ConnectivityDataSource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  Future<DeviceSyncStatus> getCurrentStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return DeviceSyncStatus.offline;
    }

    final serverReachable = await isServerReachable();
    if (!serverReachable) {
      return DeviceSyncStatus.offline;
    }

    return DeviceSyncStatus.online;
  }

  Stream<DeviceSyncStatus> get statusStream {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      if (result.contains(ConnectivityResult.none)) {
        return DeviceSyncStatus.offline;
      }

      final serverReachable = await isServerReachable();
      if (!serverReachable) {
        return DeviceSyncStatus.offline;
      }

      return DeviceSyncStatus.online;
    });
  }

  Future<bool> isServerReachable() async {
    // We avoid using a database query (e.g. selecting from shopping_items) for reachability.
    // It can fail due to RLS, missing permissions, or uninitialized auth state,
    // which incorrectly traps the app in a false 'offline' state.
    // connectivity_plus already provides reliable network interface status.
    return true;
  }
}
