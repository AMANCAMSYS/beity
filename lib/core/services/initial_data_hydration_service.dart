import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class InitialDataHydrationService extends Notifier<HydrationState> {
  bool _disposed = false;

  @override
  HydrationState build() {
    ref.onDispose(() {
      _disposed = true;
    });
    ref.watch(homeRepositoryProvider);
    ref.watch(syncCoordinatorProvider);
    ref.watch(homeLocalDataSourceProvider);
    ref.watch(shoppingModeSessionRecoveryServiceProvider);

    Future.microtask(() => hydrate());
    return HydrationState.idle();
  }

  Future<void> hydrate({bool force = false}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        if (_disposed) return;
        state = HydrationState(status: HydrationStatus.idle);
        return;
      }

      final isUserSynced = await ref
          .read(homeLocalDataSourceProvider)
          .isInitialSyncCompleted(userId);
      if (_disposed) return;
      if (isUserSynced && !force) {
        String? activeHomeId;
        try {
          await _recoverAbandonedShoppingModeSession(userId);
          if (_disposed) return;
          await ref.read(homeRepositoryProvider).syncHomesWithServer();
          if (_disposed) return;
          await _cleanupStaleShoppingModeSessions(userId);
          if (_disposed) return;
          final homes = await ref
              .read(homeRepositoryProvider)
              .getCachedUserHomes();
          if (_disposed) return;
          activeHomeId = await ref
              .read(homeLocalDataSourceProvider)
              .getActiveHomeIdForUser(userId);
          if (_disposed) return;

          if (findAvailableHomeById(homes, activeHomeId) == null) {
            final nextHome = newestAvailableHome(homes);
            if (nextHome != null) {
              activeHomeId = nextHome.id;
              await ref
                  .read(homeLocalDataSourceProvider)
                  .setActiveHome(nextHome.id, nextHome.name);
              if (_disposed) return;
              LocalCacheNotifier.notify('global', 'active_home');
            } else {
              await ref
                  .read(homeLocalDataSourceProvider)
                  .setInitialSyncCompleted(userId, false);
              if (_disposed) return;
              state = HydrationState(status: HydrationStatus.success);
              return;
            }
          }
        } catch (e) {
          AppLogger.i(
            '[InitialDataHydration] Warm resume preparation failed: $e',
          );
        }

        if (_disposed) return;
        state = HydrationState(
          status: HydrationStatus.success,
          activeHomeId: activeHomeId,
        );
        return;
      }

      if (_disposed) return;
      state = HydrationState(status: HydrationStatus.hydratingHomes);

      try {
        // 1. Sync homes first
        await _recoverAbandonedShoppingModeSession(userId);
        if (_disposed) return;
        await ref.read(homeRepositoryProvider).syncHomesWithServer();
        if (_disposed) return;
        await _cleanupStaleShoppingModeSessions(userId);
        if (_disposed) return;

        final homes = await ref
            .read(homeRepositoryProvider)
            .getCachedUserHomes();
        if (_disposed) return;
        if (homes.isEmpty) {
          // No homes found. Set user sync completed so they can go to onboarding to create one
          await ref
              .read(homeLocalDataSourceProvider)
              .setInitialSyncCompleted(userId, true);
          if (_disposed) return;
          LocalCacheNotifier.notify('global', 'homes');
          state = HydrationState(status: HydrationStatus.success);
          return;
        }

        // 2. Resolve active home ID with validation against current user's homes
        String? activeHomeId = await ref
            .read(homeLocalDataSourceProvider)
            .getActiveHomeIdForUser(userId);
        if (_disposed) return;
        final activeHome = findAvailableHomeById(homes, activeHomeId);

        if (activeHome == null) {
          // activeHomeId is stale or doesn't belong to current user — reset it
          final nextHome = newestAvailableHome(homes);
          if (nextHome == null) {
            await ref
                .read(homeLocalDataSourceProvider)
                .setInitialSyncCompleted(userId, false);
            if (_disposed) return;
            state = HydrationState(status: HydrationStatus.success);
            return;
          }
          activeHomeId = nextHome.id;
          await ref
              .read(homeLocalDataSourceProvider)
              .setActiveHome(activeHomeId, nextHome.name);
          if (_disposed) return;
          LocalCacheNotifier.notify('global', 'active_home');
        } else {
          activeHomeId = activeHome.id;
        }

        final selectedHomeId = activeHomeId;
        if (selectedHomeId.isEmpty) {
          await ref
              .read(homeLocalDataSourceProvider)
              .setInitialSyncCompleted(userId, false);
          if (_disposed) return;
          state = HydrationState(status: HydrationStatus.success);
          return;
        }

        if (_disposed) return;
        state = HydrationState(
          status: HydrationStatus.hydratingData,
          activeHomeId: selectedHomeId,
        );

        // 3. Trigger Full Initial Sync for the active home
        await ref
            .read(syncCoordinatorProvider.notifier)
            .initialFullSync(selectedHomeId);
        if (_disposed) return;

        // 4. Save success flags only after absolute successful sync
        await ref
            .read(homeLocalDataSourceProvider)
            .setInitialSyncCompleted(userId, true);
        if (_disposed) return;
        await ref
            .read(homeLocalDataSourceProvider)
            .setHomeInitialSyncCompleted(selectedHomeId, true);
        if (_disposed) return;

        state = HydrationState(
          status: HydrationStatus.success,
          activeHomeId: selectedHomeId,
        );
      } catch (e) {
        if (_disposed) return;
        state = HydrationState(
          status: HydrationStatus.error,
          error: e.toString(),
          activeHomeId: state.activeHomeId,
        );
      }
    } catch (e) {
      // Outer catch: handles errors in early validation (e.g., isInitialSyncCompleted)
      // that occur before the inner try-catch blocks.
      if (_disposed) return;
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
      await ref
          .read(shoppingModeSessionRecoveryServiceProvider)
          .recoverAbandonedSession(userId);
    } catch (e) {
      AppLogger.i(
        '[InitialDataHydration] Failed to recover shopping session: $e',
      );
    }
  }
}

final initialDataHydrationServiceProvider =
    NotifierProvider<InitialDataHydrationService, HydrationState>(() {
      return InitialDataHydrationService();
    });
