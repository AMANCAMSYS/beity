import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_coordinator.dart';
import '../services/initial_data_hydration_service.dart';
import '../services/startup_prefetch_provider.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import '../../features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../features/shopping_lists/presentation/providers/realtime_providers.dart';
import '../../features/offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/notifications/presentation/providers/unread_count_provider.dart';
import '../../features/notifications/presentation/providers/notification_preferences_provider.dart';
import '../../features/tasks/presentation/providers/task_filter_providers.dart';
import '../../features/activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../features/categories/presentation/providers/categories_provider.dart';
import '../../features/categories/presentation/providers/units_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// T034: Centralized provider lifecycle management for logout and home switching.
///
/// Instead of manually invalidating 20+ providers in AuthNotifier,
/// use this centralized service to manage provider lifecycle.
class ProviderLifecycleManager {
  final Ref _ref;

  const ProviderLifecycleManager(this._ref);

  /// Invalidate all user-scoped providers on logout.
  /// This ensures clean state without manual tracking.
  void invalidateOnLogout() {
    resetStartupPrefetchState();

    // Core services
    _ref.invalidate(initialDataHydrationServiceProvider);
    _ref.invalidate(syncCoordinatorProvider);
    _ref.invalidate(realtimeServiceProvider);

    // Offline queue
    _ref.invalidate(offlineQueueRepositoryProvider);
    _ref.invalidate(queueDataSourceProvider);
    _ref.invalidate(syncQueueLockProvider);
    _ref.invalidate(enqueueActionUseCaseProvider);
    _ref.invalidate(getPendingCountUseCaseProvider);
    _ref.invalidate(getQueueEntriesUseCaseProvider);

    // Shopping
    _ref.invalidate(shoppingListRepositoryProvider);

    // Notifications
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
    _ref.invalidate(notificationPreferencesProvider);

    // Tasks & Activity
    _ref.invalidate(taskFilterProvider);
    _ref.invalidate(activityFilterProvider);

    // Categories
    _ref.invalidate(categoryNotifierProvider);
    _ref.invalidate(unitNotifierProvider);

    // User & Homes
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(userHomesProvider);
    _ref.invalidate(cachedUserHomesProvider);
    _ref.invalidate(hasHomesProvider);
    _ref.invalidate(activeHomeIdProvider);
    _ref.invalidate(cachedActiveHomeIdProvider);
    _ref.invalidate(homesNotifierProvider);
  }

  /// Invalidate home-scoped providers on home switch.
  /// Only invalidates providers that are home-specific.
  void invalidateOnHomeSwitch() {
    _ref.invalidate(activeHomeIdProvider);
    _ref.invalidate(cachedActiveHomeIdProvider);
    _ref.invalidate(hasHomesProvider);

    // Re-hydrate data for new home
    _ref.invalidate(initialDataHydrationServiceProvider);
  }
}

/// Provider for the lifecycle manager.
final providerLifecycleManagerProvider = Provider<ProviderLifecycleManager>((
  ref,
) {
  return ProviderLifecycleManager(ref);
});
