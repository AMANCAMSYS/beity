import 'package:flutter_riverpod/legacy.dart';
import '../../features/homes/data/repositories/home_repository.dart';
import '../../features/homes/data/repositories/home_local_data_source.dart';
import '../../features/homes/data/models/home_selection.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import '../../features/shopping_mode/data/services/shopping_mode_session_recovery_service.dart';
import 'sync_coordinator.dart';
import 'supabase_service.dart';
import 'local_cache_notifier.dart';
import 'app_logger.dart';

enum HydrationStatus { idle, hydratingHomes, hydratingData, success, error }

class HydrationState {
  final HydrationStatus status;
  final String? error;
  final String? activeHomeId;

  HydrationState({required this.status, this.error, this.activeHomeId});

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
  final ShoppingModeSessionRecoveryService? _shoppingModeSessionRecoveryService;

  InitialDataHydrationService({
    required HomeRepository homeRepository,
    required SyncCoordinator syncCoordinator,
    required HomeLocalDataSource localDataSource,
    ShoppingModeSessionRecoveryService? shoppingModeSessionRecoveryService,
    bool autoHydrate = true,
  }) : _homeRepository = homeRepository,
       _syncCoordinator = syncCoordinator,
       _localDataSource = localDataSource,
       _shoppingModeSessionRecoveryService = shoppingModeSessionRecoveryService,
       super(HydrationState.idle()) {
    if (autoHydrate) {
      // Automatically trigger on initialization
      hydrate();
    }
  }

  Future<void> hydrate({bool force = false}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        state = HydrationState(status: HydrationStatus.idle);
        return;
      }

      final isUserSynced = await _localDataSource.isInitialSyncCompleted(
        userId,
      );
      if (!mounted) return;
      if (isUserSynced && !force) {
        String? activeHomeId;
        try {
          await _recoverAbandonedShoppingModeSession(userId);
          if (!mounted) return;
          await _homeRepository.syncHomesWithServer();
          if (!mounted) return;
          await _cleanupStaleShoppingModeSessions(userId);
          if (!mounted) return;
          final homes = await _homeRepository.getCachedUserHomes();
          if (!mounted) return;
          activeHomeId = await _localDataSource.getActiveHomeIdForUser(userId);
          if (!mounted) return;

          if (findAvailableHomeById(homes, activeHomeId) == null) {
            final nextHome = newestAvailableHome(homes);
            if (nextHome != null) {
              activeHomeId = nextHome.id;
              await _localDataSource.setActiveHome(nextHome.id, nextHome.name);
              if (!mounted) return;
              LocalCacheNotifier.notify('global', 'active_home');
            } else {
              await _localDataSource.setInitialSyncCompleted(userId, false);
              if (!mounted) return;
              state = HydrationState(status: HydrationStatus.success);
              return;
            }
          }
        } catch (e) {
          AppLogger.i(
            '[InitialDataHydration] Warm resume preparation failed: $e',
          );
        }

        if (!mounted) return;
        state = HydrationState(
          status: HydrationStatus.success,
          activeHomeId: activeHomeId,
        );
        return;
      }

      if (!mounted) return;
      state = HydrationState(status: HydrationStatus.hydratingHomes);

      try {
        // 1. Sync homes first
        await _recoverAbandonedShoppingModeSession(userId);
        if (!mounted) return;
        await _homeRepository.syncHomesWithServer();
        if (!mounted) return;
        await _cleanupStaleShoppingModeSessions(userId);
        if (!mounted) return;

        final homes = await _homeRepository.getCachedUserHomes();
        if (!mounted) return;
        if (homes.isEmpty) {
          // No homes found. Set user sync completed so they can go to onboarding to create one
          await _localDataSource.setInitialSyncCompleted(userId, true);
          if (!mounted) return;
          LocalCacheNotifier.notify('global', 'homes');
          state = HydrationState(status: HydrationStatus.success);
          return;
        }

        // 2. Resolve active home ID with validation against current user's homes
        String? activeHomeId = await _localDataSource.getActiveHomeIdForUser(
          userId,
        );
        if (!mounted) return;
        final activeHome = findAvailableHomeById(homes, activeHomeId);

        if (activeHome == null) {
          // activeHomeId is stale or doesn't belong to current user — reset it
          final nextHome = newestAvailableHome(homes);
          if (nextHome == null) {
            await _localDataSource.setInitialSyncCompleted(userId, false);
            if (!mounted) return;
            state = HydrationState(status: HydrationStatus.success);
            return;
          }
          activeHomeId = nextHome.id;
          await _localDataSource.setActiveHome(activeHomeId, nextHome.name);
          if (!mounted) return;
          LocalCacheNotifier.notify('global', 'active_home');
        } else {
          activeHomeId = activeHome.id;
        }

        final selectedHomeId = activeHomeId;
        if (selectedHomeId.isEmpty) {
          await _localDataSource.setInitialSyncCompleted(userId, false);
          if (!mounted) return;
          state = HydrationState(status: HydrationStatus.success);
          return;
        }

        if (!mounted) return;
        state = HydrationState(
          status: HydrationStatus.hydratingData,
          activeHomeId: selectedHomeId,
        );

        // 3. Trigger Full Initial Sync for the active home
        await _syncCoordinator.initialFullSync(selectedHomeId);
        if (!mounted) return;

        // 4. Save success flags only after absolute successful sync
        await _localDataSource.setInitialSyncCompleted(userId, true);
        if (!mounted) return;
        await _localDataSource.setHomeInitialSyncCompleted(
          selectedHomeId,
          true,
        );
        if (!mounted) return;

        state = HydrationState(
          status: HydrationStatus.success,
          activeHomeId: selectedHomeId,
        );
      } catch (e) {
        if (!mounted) return;
        state = HydrationState(
          status: HydrationStatus.error,
          error: e.toString(),
          activeHomeId: state.activeHomeId,
        );
      }
    } catch (e) {
      // Outer catch: handles errors in early validation (e.g., isInitialSyncCompleted)
      // that occur before the inner try-catch blocks.
      if (!mounted) return;
      state = HydrationState(
        status: HydrationStatus.error,
        error: e.toString(),
        activeHomeId: state.activeHomeId,
      );
    }
  }

  Future<void> _cleanupStaleShoppingModeSessions(String userId) async {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 2));
      await SupabaseService.client
          .from('shopping_mode_sessions')
          .update({'ended_at': now.toIso8601String()})
          .eq('user_id', userId)
          .isFilter('ended_at', null)
          .lt('started_at', cutoff.toIso8601String());
    } catch (e) {
      AppLogger.i(
        '[InitialDataHydration] Failed to cleanup stale sessions: $e',
      );
    }
  }

  Future<void> _recoverAbandonedShoppingModeSession(String userId) async {
    try {
      await _shoppingModeSessionRecoveryService?.recoverAbandonedSession(
        userId,
      );
    } catch (e) {
      AppLogger.i(
        '[InitialDataHydration] Failed to recover shopping session: $e',
      );
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
        shoppingModeSessionRecoveryService: ref.watch(
          shoppingModeSessionRecoveryServiceProvider,
        ),
      );
    });
