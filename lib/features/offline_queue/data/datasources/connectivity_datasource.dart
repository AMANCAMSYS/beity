import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/device_sync_status.dart';

class ConnectivityDataSource {
  final Connectivity _connectivity;
  final SupabaseClient _supabase;

  ConnectivityDataSource({
    Connectivity? connectivity,
    SupabaseClient? supabase,
  })  : _connectivity = connectivity ?? Connectivity(),
        _supabase = supabase ?? Supabase.instance.client;

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
    try {
      await _supabase.from('shopping_items').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
