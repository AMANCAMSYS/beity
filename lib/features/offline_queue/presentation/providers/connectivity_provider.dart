import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';

import '../../data/datasources/connectivity_datasource.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../../data/repositories/supabase_connectivity_repository.dart';
import '../../domain/entities/device_sync_status.dart';

final connectivityDataSourceProvider = Provider<ConnectivityDataSource>((ref) {
  return ConnectivityDataSource();
});

final connectivityRepositoryProvider = Provider<ConnectivityRepository>((ref) {
  final dataSource = ref.watch(connectivityDataSourceProvider);
  return SupabaseConnectivityRepository(dataSource);
});

final connectivityStatusProvider = StreamProvider<DeviceSyncStatus>((ref) {
  final repository = ref.watch(connectivityRepositoryProvider);
  return repository.statusStream;
});

final currentConnectivityProvider = FutureProvider<DeviceSyncStatus>((ref) async {
  final repository = ref.watch(connectivityRepositoryProvider);
  return repository.getCurrentStatus();
});

final rawConnectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final canSyncNowProvider = Provider<bool>((ref) {
  final isOnline = ref.watch(connectivityStatusProvider).valueOrNull?.isOnline ?? true;
  if (!isOnline) return false;

  final settings = ref.watch(appSettingsProvider);
  if (settings.syncOverWifiOnly) {
    final results = ref.watch(rawConnectivityProvider).valueOrNull ?? [];
    return results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);
  }

  return true;
});
