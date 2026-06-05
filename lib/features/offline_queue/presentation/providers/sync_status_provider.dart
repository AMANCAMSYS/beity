import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device_sync_status.dart';
import 'offline_queue_provider.dart';
import 'connectivity_provider.dart';

class SyncStatusState {
  final DeviceSyncStatus deviceStatus;
  final int pendingCount;
  final int failedCount;
  final bool isSyncing;

  SyncStatusState({
    required this.deviceStatus,
    required this.pendingCount,
    required this.failedCount,
    this.isSyncing = false,
  });

  SyncStatusState copyWith({
    DeviceSyncStatus? deviceStatus,
    int? pendingCount,
    int? failedCount,
    bool? isSyncing,
  }) {
    return SyncStatusState(
      deviceStatus: deviceStatus ?? this.deviceStatus,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  bool get hasPendingActions => pendingCount > 0;
  bool get hasFailedActions => failedCount > 0;
  bool get isOffline => deviceStatus.isOffline;
  bool get isOnline => deviceStatus.isOnline;
}

final syncStatusProvider = FutureProvider.family<SyncStatusState, String>((
  ref,
  homeId,
) async {
  final connectivityStatus = await ref.watch(
    currentConnectivityProvider.future,
  );
  final pendingCount = await ref.watch(pendingCountProvider(homeId).future);

  final failedEntries = await ref
      .watch(offlineQueueRepositoryProvider)
      .getFailedEntries(homeId);

  return SyncStatusState(
    deviceStatus: connectivityStatus,
    pendingCount: pendingCount,
    failedCount: failedEntries.length,
  );
});
