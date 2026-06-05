import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import 'sync_coordinator.dart';
import 'realtime_sync_service.dart';
import 'initial_data_hydration_service.dart';
import 'app_logger.dart';

final Set<String> _prefetchedHomeIds = <String>{};

void resetStartupPrefetchState() {
  _prefetchedHomeIds.clear();
}

void resetStartupPrefetchStateForTesting() {
  resetStartupPrefetchState();
}

void markStartupPrefetchCompletedForTesting(String homeId) {
  if (homeId.isEmpty) return;
  _prefetchedHomeIds.add(homeId);
}

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
      final isHomeSynced = await localDataSource.isHomeInitialSyncCompleted(
        homeId,
      );

      final coordinator = ref.read(syncCoordinatorProvider.notifier);
      if (!isHomeSynced) {
        await coordinator.initialFullSync(homeId);
        await localDataSource.setHomeInitialSyncCompleted(homeId, true);
      } else {
        await coordinator.smartResumeSync(homeId);
      }

      // Postpone Supabase Realtime subscription to free up launch thread
      Future.delayed(const Duration(milliseconds: 600), () {
        ref.read(realtimeSyncServiceProvider).init(homeId);
      });

      _prefetchedHomeIds.add(homeId);
    } catch (e) {
      AppLogger.i('[StartupPrefetch] Sync error: $e');
    }
  });
});
