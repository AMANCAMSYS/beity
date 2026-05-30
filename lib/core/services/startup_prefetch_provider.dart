import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import 'sync_coordinator.dart';
import 'realtime_sync_service.dart';
import 'initial_data_hydration_service.dart';

/// Progressive startup prefetch provider rewritten to leverage the global SyncCoordinator.
///
/// Ensures home metadata is resolved first, then silently triggers global background
/// delta synchronization without blocking UI rendering or showing disruptive loading screen blockers.
final startupPrefetchProvider = Provider<void>((ref) {
  final homeId = ref.watch(cachedActiveHomeIdProvider);
  final hydrationState = ref.watch(initialDataHydrationServiceProvider);

  // If currently hydrating, skip background sync since hydration service is performing it
  if (hydrationState.status == HydrationStatus.hydratingHomes ||
      hydrationState.status == HydrationStatus.hydratingData) {
    return;
  }

  if (homeId == null || homeId.isEmpty) {
    return;
  }

  Future.microtask(() async {
    try {
      final localDataSource = ref.read(homeLocalDataSourceProvider);
      final isHomeSynced = await localDataSource.isHomeInitialSyncCompleted(homeId);

      final coordinator = ref.read(syncCoordinatorProvider.notifier);
      if (!isHomeSynced) {
        // Explicit flag: home not hydrated yet, run initialFullSync!
        await coordinator.initialFullSync(homeId);
        await localDataSource.setHomeInitialSyncCompleted(homeId, true);
      } else {
        // Standard resume sync policy
        await coordinator.smartResumeSync(homeId);
      }

      // 3. Postpone Supabase Realtime subscription by 600ms to free up launch thread (Phase 5)
      Future.delayed(const Duration(milliseconds: 600), () {
        ref.read(realtimeSyncServiceProvider).init(homeId);
      });
    } catch (e, stack) {
      assert(() {
        print('startupPrefetchProvider sync error: $e\n$stack');
        return true;
      }());
    }
  });
});
