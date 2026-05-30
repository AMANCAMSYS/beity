import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/homes/data/repositories/home_repository.dart';
import '../../features/homes/data/repositories/home_local_data_source.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import 'sync_coordinator.dart';
import 'supabase_service.dart';
import 'local_cache_notifier.dart';

enum HydrationStatus {
  idle,
  hydratingHomes,
  hydratingData,
  success,
  error,
}

class HydrationState {
  final HydrationStatus status;
  final String? error;
  final String? activeHomeId;

  HydrationState({
    required this.status,
    this.error,
    this.activeHomeId,
  });

  HydrationState copyWith({
    HydrationStatus? status,
    String? error,
    String? activeHomeId,
  }) {
    return HydrationState(
      status: status ?? this.status,
      error: error ?? this.error,
      activeHomeId: activeHomeId ?? this.activeHomeId,
    );
  }

  factory HydrationState.idle() => HydrationState(status: HydrationStatus.idle);
}

class InitialDataHydrationService extends StateNotifier<HydrationState> {
  final HomeRepository _homeRepository;
  final SyncCoordinator _syncCoordinator;
  final HomeLocalDataSource _localDataSource;

  InitialDataHydrationService({
    required HomeRepository homeRepository,
    required SyncCoordinator syncCoordinator,
    required HomeLocalDataSource localDataSource,
    bool autoHydrate = true,
  })  : _homeRepository = homeRepository,
        _syncCoordinator = syncCoordinator,
        _localDataSource = localDataSource,
        super(HydrationState.idle()) {
    if (autoHydrate) {
      // Automatically trigger on initialization
      hydrate();
    }
  }

  Future<void> hydrate({bool force = false}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      state = HydrationState(status: HydrationStatus.idle);
      return;
    }

    final isUserSynced = await _localDataSource.isInitialSyncCompleted(userId);
    if (isUserSynced && !force) {
      state = HydrationState(status: HydrationStatus.success);
      return;
    }

    state = HydrationState(status: HydrationStatus.hydratingHomes);

    try {
      // 1. Sync homes first
      await _homeRepository.syncHomesWithServer();

      final homes = await _homeRepository.getCachedUserHomes();
      if (homes.isEmpty) {
        // No homes found. Set user sync completed so they can go to onboarding to create one
        await _localDataSource.setInitialSyncCompleted(userId, true);
        state = HydrationState(status: HydrationStatus.success);
        return;
      }

      // 2. Resolve active home ID
      String? activeHomeId = await _localDataSource.getActiveHomeIdForUser(userId);
      final isVal = homes.any((h) => h.id == activeHomeId);

      if (activeHomeId == null || activeHomeId.isEmpty || !isVal) {
        // Choose suitable home fallback:
        if (homes.length == 1) {
          activeHomeId = homes.first.id;
        } else {
          // If multiple homes, choose the first (or newest) one
          activeHomeId = homes.first.id;
        }
        await _localDataSource.setActiveHome(activeHomeId, homes.first.name);
        LocalCacheNotifier.notify('global', 'active_home');
      }

      state = HydrationState(status: HydrationStatus.hydratingData, activeHomeId: activeHomeId);

      // 3. Trigger Full Initial Sync for the active home
      await _syncCoordinator.initialFullSync(activeHomeId);

      // 4. Save success flags only after absolute successful sync
      await _localDataSource.setInitialSyncCompleted(userId, true);
      await _localDataSource.setHomeInitialSyncCompleted(activeHomeId, true);

      state = HydrationState(status: HydrationStatus.success, activeHomeId: activeHomeId);
    } catch (e) {
      state = HydrationState(status: HydrationStatus.error, error: e.toString(), activeHomeId: state.activeHomeId);
    }
  }
}

final initialDataHydrationServiceProvider =
    StateNotifierProvider<InitialDataHydrationService, HydrationState>((ref) {
  final homeRepository = ref.watch(homeRepositoryProvider);
  final syncCoordinator = ref.watch(syncCoordinatorProvider.notifier);
  final localDataSource = ref.watch(homeLocalDataSourceProvider);

  return InitialDataHydrationService(
    homeRepository: homeRepository,
    syncCoordinator: syncCoordinator,
    localDataSource: localDataSource,
  );
});
