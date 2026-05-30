import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shopping_lists/data/repositories/shopping_list_repository.dart';
import '../../features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/presentation/providers/expense_providers.dart';
import '../../features/inventory/data/repositories/inventory_repository.dart';
import '../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../features/categories/data/repositories/category_repository.dart';
import '../../features/categories/presentation/providers/categories_provider.dart';
import '../../features/homes/data/repositories/home_repository.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import '../../features/offline_queue/data/repositories/offline_queue_repository.dart';
import '../../features/offline_queue/domain/usecases/sync_queue_usecase.dart';
import '../../features/offline_queue/presentation/providers/offline_queue_provider.dart';
import 'shared_prefs_provider.dart';

/// The status of the global synchronization process.
enum SyncStatus {
  idle,
  syncing,
  success,
  partiallySynced,
  error,
}

/// Represents the detailed state of background synchronization.
class SyncState {
  final SyncStatus status;
  final Map<String, String> domainErrors;
  final Map<String, DateTime> lastSyncTimes;

  SyncState({
    required this.status,
    this.domainErrors = const {},
    this.lastSyncTimes = const {},
  });

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    Map<String, String>? domainErrors,
    Map<String, DateTime>? lastSyncTimes,
  }) {
    return SyncState(
      status: status ?? this.status,
      domainErrors: domainErrors ?? this.domainErrors,
      lastSyncTimes: lastSyncTimes ?? this.lastSyncTimes,
    );
  }
}

/// A global background synchronization coordinator.
///
/// Orchestrates delta synchronization across all features in parallel
/// with complete domain-level error isolation and fine-grained, home-specific throttling.
class SyncCoordinator extends StateNotifier<SyncState> {
  final TaskRepository _taskRepository;
  final ShoppingListRepository _shoppingRepository;
  final ExpenseRepository _expenseRepository;
  final InventoryRepository _inventoryRepository;
  final CategoryRepository _categoryRepository;
  final HomeRepository _homeRepository;
  final OfflineQueueRepository _offlineQueueRepository;
  final SyncQueueUseCase _syncQueueUseCase;
  Completer<void>? _smartResumeLock;

  SyncCoordinator({
    required TaskRepository taskRepository,
    required ShoppingListRepository shoppingRepository,
    required ExpenseRepository expenseRepository,
    required InventoryRepository inventoryRepository,
    required CategoryRepository categoryRepository,
    required HomeRepository homeRepository,
    required OfflineQueueRepository offlineQueueRepository,
    required SyncQueueUseCase syncQueueUseCase,
  })  : _taskRepository = taskRepository,
        _shoppingRepository = shoppingRepository,
        _expenseRepository = expenseRepository,
        _inventoryRepository = inventoryRepository,
        _categoryRepository = categoryRepository,
        _homeRepository = homeRepository,
        _offlineQueueRepository = offlineQueueRepository,
        _syncQueueUseCase = syncQueueUseCase,
        super(SyncState(status: SyncStatus.idle));

  static const _defaultThrottle = Duration(seconds: 10);

  // Custom throttling durations per domain (Requirement 10)
  static const Map<String, Duration> _customThrottling = {
    'homes': Duration(seconds: 30),        // Homes rarely change
    'home_members': Duration(seconds: 20), // Members rarely change
    'shopping': Duration(seconds: 5),      // Shopping can be synced frequently
    'tasks': Duration(seconds: 10),
    'expenses': Duration(seconds: 15),
    'inventory': Duration(seconds: 15),
    'categories': Duration(seconds: 30),
  };

  String _getThrottleKey(String homeId, String domain) => 'last_sync_throttle_${homeId}_$domain';



  /// Run background synchronization for a specific home across all domains.
  ///
  /// [force] bypasses throttling checks for all domains.
  /// [targetDomain] targets a single domain for delta sync.
  Future<void> syncAll(String homeId, {bool force = false, String? targetDomain}) async {
    if (homeId.isEmpty) return;

    // Prevent re-entry if general syncing is currently executing
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, domainErrors: {});

    final Map<String, String> errors = {};
    final now = DateTime.now();

    // Define helper to run a specific domain sync with try-catch isolation and throttling
    Future<bool> runDomainSync(String domain, Future<void> Function() syncAction) async {
      if (targetDomain != null && targetDomain != domain) {
        return true; // Skip domains other than the targeted one
      }

      // Safety check: if homeId is placeholder/empty, skip home-specific features
      if ((homeId == 'placeholder' || homeId.isEmpty) && domain != 'homes') {
        return true;
      }

      if (!force) {
        final lastSync = _getLastSyncTime(homeId, domain);
        final throttle = _customThrottling[domain] ?? _defaultThrottle;
        if (now.difference(lastSync) < throttle) {
          // Throttled: Skip remote fetch and assume success
          return true;
        }
      }

      try {
        await syncAction();
        await _updateLastSyncTime(homeId, domain, now);
        return true;
      } catch (e) {
        errors[domain] = e.toString();
        return false;
      }
    }

    // Execute all domain syncs in parallel to optimize latency and bandwidth (Requirement 10)
    final List<bool> results = await Future.wait([
      runDomainSync('homes', () => _homeRepository.syncHomesWithServer()),
      runDomainSync('home_members', () => _homeRepository.syncMembersWithServer(homeId)),
      runDomainSync('shopping', () => _shoppingRepository.syncShoppingWithServer(homeId)),
      runDomainSync('tasks', () => _taskRepository.syncTasksWithServer(homeId)),
      runDomainSync('expenses', () => _expenseRepository.syncExpensesWithServer(homeId)),
      runDomainSync('inventory', () => _inventoryRepository.syncInventoryWithServer(homeId)),
      runDomainSync('categories', () => _categoryRepository.syncCategoriesWithServer(homeId)),
    ]);

    // Determine aggregate status
    final successCount = results.where((r) => r).length;
    final failedCount = errors.length;

    SyncStatus finalStatus;
    if (failedCount == 0) {
      finalStatus = SyncStatus.success;
      await updateLastSuccessfulSyncTime(homeId, now);
    } else if (successCount > 0) {
      finalStatus = SyncStatus.partiallySynced;
    } else {
      finalStatus = SyncStatus.error;
    }

    // Prepare updated last sync times map
    final Map<String, DateTime> syncTimes = Map.from(state.lastSyncTimes);
    for (final domain in ['homes', 'home_members', 'shopping', 'tasks', 'expenses', 'inventory', 'categories']) {
      syncTimes[domain] = _getLastSyncTime(homeId, domain);
    }

    state = SyncState(
      status: finalStatus,
      domainErrors: errors,
      lastSyncTimes: syncTimes,
    );
  }

  /// Runs a complete, non-throttled initial sync for the given home ID across all domains.
  ///
  /// This is used exclusively by [InitialDataHydrationService] on the very first login
  /// or cold bootstrap after installation when local cache is empty.
  Future<void> initialFullSync(String homeId) async {
    if (homeId.isEmpty) return;

    state = state.copyWith(status: SyncStatus.syncing, domainErrors: {});

    final Map<String, String> errors = {};
    final now = DateTime.now();

    Future<bool> runDomainSync(String domain, Future<void> Function() syncAction) async {
      // Safety check: if homeId is placeholder/empty, skip home-specific features
      if ((homeId == 'placeholder' || homeId.isEmpty) && domain != 'homes') {
        return true;
      }

      try {
        await syncAction();
        await _updateLastSyncTime(homeId, domain, now);
        return true;
      } catch (e) {
        errors[domain] = e.toString();
        return false;
      }
    }

    // Run ALL domain syncs in parallel to optimize latency and bandwidth
    final List<bool> results = await Future.wait([
      runDomainSync('homes', () => _homeRepository.syncHomesWithServer()),
      runDomainSync('home_members', () => _homeRepository.syncMembersWithServer(homeId)),
      runDomainSync('shopping', () => _shoppingRepository.syncShoppingWithServer(homeId)),
      runDomainSync('tasks', () => _taskRepository.syncTasksWithServer(homeId)),
      runDomainSync('expenses', () => _expenseRepository.syncExpensesWithServer(homeId)),
      runDomainSync('inventory', () => _inventoryRepository.syncInventoryWithServer(homeId)),
      runDomainSync('categories', () => _categoryRepository.syncCategoriesWithServer(homeId)),
    ]);

    final successCount = results.where((r) => r).length;
    final failedCount = errors.length;

    SyncStatus finalStatus;
    if (failedCount == 0) {
      finalStatus = SyncStatus.success;
      await updateLastSuccessfulSyncTime(homeId, now);
    } else if (successCount > 0) {
      finalStatus = SyncStatus.partiallySynced;
    } else {
      finalStatus = SyncStatus.error;
    }

    final Map<String, DateTime> syncTimes = Map.from(state.lastSyncTimes);
    for (final domain in ['homes', 'home_members', 'shopping', 'tasks', 'expenses', 'inventory', 'categories']) {
      syncTimes[domain] = _getLastSyncTime(homeId, domain);
    }

    state = SyncState(
      status: finalStatus,
      domainErrors: errors,
      lastSyncTimes: syncTimes,
    );

    if (failedCount > 0) {
      final failedDomains = errors.keys.join(', ');
      throw Exception('فشلت مزامنة بعض الأقسام ($failedDomains). يرجى التحقق من الاتصال.');
    }
  }

  String _getSuccessfulSyncKey(String homeId) => 'last_successful_sync_at_home_$homeId';

  /// Get the persistent last successful sync time for a specific home
  DateTime getLastSuccessfulSyncTime(String homeId) {
    try {
      final prefs = AppPreferences.instance;
      final timeStr = prefs.getString(_getSuccessfulSyncKey(homeId));
      if (timeStr == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(timeStr);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  /// Update the persistent last successful sync time for a specific home
  Future<void> updateLastSuccessfulSyncTime(String homeId, DateTime time) async {
    try {
      final key = 'last_successful_sync_at_home_$homeId';
      await AppPreferences.instance.setString(key, time.toIso8601String());
    } catch (e, stack) {
      assert(() {
        print('SyncCoordinator.updateLastSuccessfulSyncTime error: $e\n$stack');
        return true;
      }());
    }
  }

  // Individual domain sync time helpers
  DateTime _getLastSyncTime(String homeId, String domain) {
    try {
      final key = 'last_sync_throttle_${homeId}_$domain';
      final value = AppPreferences.instance.getString(key);
      if (value != null) {
        return DateTime.parse(value);
      }
    } catch (e, stack) {
      assert(() {
        print('SyncCoordinator._getLastSyncTime error: $e\n$stack');
        return true;
      }());
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _updateLastSyncTime(String homeId, String domain, DateTime time) async {
    try {
      final key = 'last_sync_throttle_${homeId}_$domain';
      await AppPreferences.instance.setString(key, time.toIso8601String());
    } catch (e, stack) {
      assert(() {
        print('SyncCoordinator._updateLastSyncTime error: $e\n$stack');
        return true;
      }());
    }
  }

  /// TIERED SMART RESUME SYNC POLICY
  ///
  /// Checks duration since last successful sync and processes pending outbox entries first.
  Future<void> smartResumeSync(String homeId) async {
    if (homeId.isEmpty) return;

    // Prevent re-entry using both State Status and a dedicated Completer Mutex lock
    if (state.status == SyncStatus.syncing) return;
    if (_smartResumeLock != null && !_smartResumeLock!.isCompleted) {
      return _smartResumeLock!.future;
    }

    _smartResumeLock = Completer<void>();

    try {
      final now = DateTime.now();
      final lastSync = getLastSuccessfulSyncTime(homeId);
      final elapsed = now.difference(lastSync);

      // 1. If last sync was less than 30 seconds ago, do nothing
      if (elapsed < const Duration(seconds: 30) && lastSync.millisecondsSinceEpoch > 0) {
        return;
      }

      // 2. If there are pending entries in the Offline Outbox Queue, sync outbox first!
      try {
        final pendingCount = await _offlineQueueRepository.getPendingCount(homeId);
        if (pendingCount > 0) {
          state = state.copyWith(status: SyncStatus.syncing, domainErrors: {});
          final outboxResult = await _syncQueueUseCase.execute(homeId);
          if (!outboxResult.allSucceeded) {
            // If outbox sync fails, log error but proceed to delta sync with remaining items
            state = state.copyWith(status: SyncStatus.idle);
          }
        }
      } catch (e, stack) {
        assert(() {
          print('SyncCoordinator.smartResumeSync outbox error: $e\n$stack');
          return true;
        }());
        // Outbox failed or not ready, proceed to standard sync
      }

      // 3. Multi-tiered Smart Sync Policy based on elapsed duration (Phase 3)
      if (elapsed < const Duration(minutes: 5) && lastSync.millisecondsSinceEpoch > 0) {
        // 30 seconds to 5 minutes: Light Sync (Shopping only)
        await syncAll(homeId, force: true, targetDomain: 'shopping');
      } else if (elapsed < const Duration(minutes: 60) && lastSync.millisecondsSinceEpoch > 0) {
        // 5 minutes to 60 minutes: Basic Sync (Shopping, Homes, Members)
        state = state.copyWith(status: SyncStatus.syncing, domainErrors: {});
        try {
          await Future.wait([
            _shoppingRepository.syncShoppingWithServer(homeId),
            _homeRepository.syncHomesWithServer(),
            _homeRepository.syncMembersWithServer(homeId),
          ]);
          await _updateLastSyncTime(homeId, 'shopping', now);
          await _updateLastSyncTime(homeId, 'homes', now);
          await _updateLastSyncTime(homeId, 'home_members', now);
          await updateLastSuccessfulSyncTime(homeId, now);
          state = SyncState(status: SyncStatus.success);
        } catch (e) {
          state = SyncState(status: SyncStatus.partiallySynced, domainErrors: {'resume_sync': e.toString()});
        }
      } else {
        // >= 60 minutes or first run: Full Background Sync
        await syncAll(homeId, force: true);
      }
    } finally {
      _smartResumeLock!.complete();
    }
  }
}

/// Provider for [SyncCoordinator] state notifier
final syncCoordinatorProvider = StateNotifierProvider<SyncCoordinator, SyncState>((ref) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final shoppingRepo = ref.watch(shoppingListRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final homeRepo = ref.watch(homeRepositoryProvider);
  final queueRepo = ref.watch(offlineQueueRepositoryProvider);
  final syncQueueUseCase = ref.watch(syncQueueUseCaseProvider);

  return SyncCoordinator(
    taskRepository: taskRepo,
    shoppingRepository: shoppingRepo,
    expenseRepository: expenseRepo,
    inventoryRepository: inventoryRepo,
    categoryRepository: categoryRepo,
    homeRepository: homeRepo,
    offlineQueueRepository: queueRepo,
    syncQueueUseCase: syncQueueUseCase,
  );
});
