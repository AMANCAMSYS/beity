import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../offline_queue/presentation/widgets/sync_status_banner.dart';
import '../../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../../offline_queue/domain/entities/sync_status.dart';

class IsolatedSyncStatusBanner extends ConsumerWidget {
  final String homeId;
  const IsolatedSyncStatusBanner({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final isOffline = connectivityStatus.value?.isOffline ?? false;
    final canSyncNow = ref.watch(canSyncNowProvider);
    final pendingCount = homeId.isNotEmpty
        ? ref.watch(pendingCountProvider(homeId)).value ?? 0
        : 0;
    final failedCount = homeId.isNotEmpty
        ? ref.watch(failedCountProvider(homeId)).value ?? 0
        : 0;

    return SyncStatusBanner(
      pendingCount: pendingCount,
      failedCount: failedCount,
      isOffline: isOffline,
      canSyncNow: canSyncNow,
      onRetryAll: () async {
        final repository = ref.read(offlineQueueRepositoryProvider);
        final failedEntries = await repository.getFailedEntries(homeId);
        for (final entry in failedEntries) {
          await repository.updateEntryStatus(
            entryId: entry.id!,
            status: SyncStatus.pending,
          );
        }
        ref.invalidate(queueEntriesProvider(homeId));
        ref.invalidate(pendingCountProvider(homeId));
        ref.invalidate(failedCountProvider(homeId));
      },
    );
  }
}
