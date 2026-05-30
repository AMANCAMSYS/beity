import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_cache_notifier.dart';
import 'supabase_service.dart';
import 'sync_coordinator.dart';
import '../../features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/expenses/presentation/providers/expense_providers.dart';
import '../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../features/categories/presentation/providers/categories_provider.dart';
import '../../features/shopping_lists/data/models/shopping_list_model.dart';
import '../../features/shopping_lists/data/models/shopping_item_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/inventory/data/models/inventory_item_model.dart';
import '../../features/categories/data/models/category_model.dart';

/// Service responsible for managing Supabase Realtime Postgres event subscriptions
/// and mapping incoming event payloads directly into the local persistent cache.
class RealtimeSyncService {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _channel;
  String? _currentHomeId;

  // Debounce timers per domain to throttle consecutive rapid updates
  final Map<String, Timer> _debounceTimers = {};

  RealtimeSyncService(this._client, this._ref);

  void init(String homeId) {
    if (homeId.isEmpty) return;
    if (_currentHomeId == homeId) return;

    // Unsubscribe from previous channels first
    unsubscribe();

    _currentHomeId = homeId;

    // Subscribe to Postgres Changes on all major tables
    _channel = _client.channel('realtime_sync:$homeId');

    // 1. shopping_lists
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_lists',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _handleShoppingListEvent(payload),
    );

    // 2. shopping_items (All items, filtered by home list IDs in client side)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_items',
      callback: (payload) => _handleShoppingItemEvent(payload),
    );

    // 3. tasks
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _handleTaskEvent(payload),
    );

    // 4. expenses
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'expenses',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _handleExpenseEvent(payload),
    );

    // 5. inventory_items
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'inventory_items',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _handleInventoryItemEvent(payload),
    );

    // 6. categories
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'categories',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _handleCategoryEvent(payload),
    );

    // 7. home_members (Requirement 11)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'home_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _handleHomeMemberEvent(payload),
    );

    _channel!.subscribe();
  }

  void unsubscribe() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    if (_channel != null) {
      try {
        _client.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
    }
    _currentHomeId = null;
  }

  void _debounceSync(String domain, Future<void> Function() action) {
    _debounceTimers[domain]?.cancel();
    _debounceTimers[domain] = Timer(const Duration(milliseconds: 800), () async {
      try {
        await action();
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._debounceSync error in domain $domain: $e\n$stack');
          return true;
        }());
      }
    });
  }

  // MARK: - Event Handlers

  Future<void> _handleShoppingListEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    _debounceSync('shopping_lists', () async {
      try {
        final localDS = _ref.read(shoppingLocalDataSourceProvider);
        final currentLists = await localDS.getShoppingListsStreamCache(homeId: homeId);
        List<ShoppingListModel> updatedLists = List.from(currentLists);

        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.insert) {
          if (record.isNotEmpty) {
            final newList = ShoppingListModel.fromJson(record);
            if (!updatedLists.any((l) => l.id == newList.id)) {
              updatedLists.add(newList);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (record.isNotEmpty) {
            final updatedList = ShoppingListModel.fromJson(record);
            final index = updatedLists.indexWhere((l) => l.id == updatedList.id);
            if (index != -1) {
              if (updatedList.deletedAt != null) {
                updatedLists.removeAt(index);
              } else {
                updatedLists[index] = updatedList;
              }
            } else if (updatedList.deletedAt == null) {
              updatedLists.add(updatedList);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            updatedLists.removeWhere((l) => l.id == id);
          }
        }

        await localDS.saveShoppingListsStreamCache(homeId: homeId, lists: updatedLists);
        LocalCacheNotifier.notify(homeId, 'shopping_lists');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleShoppingListEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }

  Future<void> _handleShoppingItemEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    final record = payload.newRecord;
    final oldRecord = payload.oldRecord;
    final listId = (record['list_id'] ?? oldRecord['list_id']) as String?;
    if (listId == null) return;

    // T3: Filter out events not belonging to this home immediately before debouncing to save resource loop
    final localDS = _ref.read(shoppingLocalDataSourceProvider);
    final currentLists = await localDS.getShoppingListsStreamCache(homeId: homeId);
    final belongsToHome = currentLists.any((l) => l.id == listId);
    if (!belongsToHome) {
      // In case a new list sync is pending, trigger background sync
      _ref.read(syncCoordinatorProvider.notifier).syncAll(homeId, targetDomain: 'shopping');
      return;
    }

    _debounceSync('shopping_items_$listId', () async {
      try {
        final currentItems = await localDS.getShoppingItemsStreamCache(listId: listId);
        List<ShoppingItemModel> updatedItems = List.from(currentItems);
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.insert) {
          if (record.isNotEmpty) {
            final newItem = ShoppingItemModel.fromJson(record);
            if (!updatedItems.any((i) => i.id == newItem.id)) {
              updatedItems.add(newItem);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (record.isNotEmpty) {
            final updatedItem = ShoppingItemModel.fromJson(record);
            final index = updatedItems.indexWhere((i) => i.id == updatedItem.id);
            if (index != -1) {
              if (updatedItem.deletedAt != null) {
                updatedItems.removeAt(index);
              } else {
                updatedItems[index] = updatedItem;
              }
            } else if (updatedItem.deletedAt == null) {
              updatedItems.add(updatedItem);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            updatedItems.removeWhere((i) => i.id == id);
          }
        }

        await localDS.saveShoppingItemsStreamCache(listId: listId, items: updatedItems);
        LocalCacheNotifier.notify(homeId, 'shopping_items');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleShoppingItemEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }

  Future<void> _handleTaskEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    _debounceSync('tasks', () async {
      try {
        final localDS = _ref.read(taskLocalDataSourceProvider);
        final currentTasks = await localDS.getTasksStreamCache(homeId: homeId);
        List<TaskModel> updatedTasks = List.from(currentTasks);

        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.insert) {
          if (record.isNotEmpty) {
            final newTask = TaskModel.fromJson(record);
            if (!updatedTasks.any((t) => t.id == newTask.id)) {
              updatedTasks.add(newTask);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (record.isNotEmpty) {
            final updatedTask = TaskModel.fromJson(record);
            final index = updatedTasks.indexWhere((t) => t.id == updatedTask.id);
            if (index != -1) {
              if (updatedTask.deletedAt != null || updatedTask.archivedAt != null) {
                updatedTasks.removeAt(index);
              } else {
                updatedTasks[index] = updatedTask;
              }
            } else if (updatedTask.deletedAt == null && updatedTask.archivedAt == null) {
              updatedTasks.add(updatedTask);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            updatedTasks.removeWhere((t) => t.id == id);
          }
        }

        await localDS.saveTasksStreamCache(homeId: homeId, tasks: updatedTasks);
        LocalCacheNotifier.notify(homeId, 'tasks');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleTaskEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }

  Future<void> _handleExpenseEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    _debounceSync('expenses', () async {
      try {
        final localDS = _ref.read(expenseLocalDataSourceProvider);
        final currentExpenses = await localDS.getExpensesStreamCache(homeId: homeId);
        List<ExpenseModel> updatedExpenses = List.from(currentExpenses);

        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.insert) {
          if (record.isNotEmpty) {
            final newExpense = ExpenseModel.fromJson(record);
            if (!updatedExpenses.any((e) => e.id == newExpense.id)) {
              updatedExpenses.add(newExpense);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (record.isNotEmpty) {
            final updatedExpense = ExpenseModel.fromJson(record);
            final index = updatedExpenses.indexWhere((e) => e.id == updatedExpense.id);
            if (index != -1) {
              if (updatedExpense.deletedAt != null) {
                updatedExpenses.removeAt(index);
              } else {
                updatedExpenses[index] = updatedExpense;
              }
            } else if (updatedExpense.deletedAt == null) {
              updatedExpenses.add(updatedExpense);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            updatedExpenses.removeWhere((e) => e.id == id);
          }
        }

        await localDS.saveExpensesStreamCache(homeId: homeId, expenses: updatedExpenses);
        LocalCacheNotifier.notify(homeId, 'expenses');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleExpenseEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }

  Future<void> _handleInventoryItemEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    _debounceSync('inventory', () async {
      try {
        final localDS = _ref.read(inventoryLocalDataSourceProvider);
        final currentItems = await localDS.getInventoryItemsStreamCache(homeId: homeId);
        List<InventoryItemModel> updatedItems = List.from(currentItems);

        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.insert) {
          if (record.isNotEmpty) {
            final newItem = InventoryItemModel.fromJson(record);
            if (!updatedItems.any((i) => i.id == newItem.id)) {
              updatedItems.add(newItem);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (record.isNotEmpty) {
            final updatedItem = InventoryItemModel.fromJson(record);
            final index = updatedItems.indexWhere((i) => i.id == updatedItem.id);
            if (index != -1) {
              if (updatedItem.deletedAt != null) {
                updatedItems.removeAt(index);
              } else {
                updatedItems[index] = updatedItem;
              }
            } else if (updatedItem.deletedAt == null) {
              updatedItems.add(updatedItem);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            updatedItems.removeWhere((i) => i.id == id);
          }
        }

        await localDS.saveInventoryItemsStreamCache(homeId: homeId, items: updatedItems);
        LocalCacheNotifier.notify(homeId, 'inventory');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleInventoryItemEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }

  Future<void> _handleCategoryEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    _debounceSync('categories', () async {
      try {
        final localDS = _ref.read(categoryLocalDataSourceProvider);
        final currentCategories = await localDS.getCategories(homeId: homeId);
        List<CategoryModel> updatedCategories = List.from(currentCategories);

        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.insert) {
          if (record.isNotEmpty) {
            final newCategory = CategoryModel.fromJson(record);
            if (!updatedCategories.any((c) => c.id == newCategory.id)) {
              updatedCategories.add(newCategory);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (record.isNotEmpty) {
            final updatedCategory = CategoryModel.fromJson(record);
            final index = updatedCategories.indexWhere((c) => c.id == updatedCategory.id);
            if (index != -1) {
              if (updatedCategory.deletedAt != null) {
                updatedCategories.removeAt(index);
              } else {
                updatedCategories[index] = updatedCategory;
              }
            } else if (updatedCategory.deletedAt == null) {
              updatedCategories.add(updatedCategory);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            updatedCategories.removeWhere((c) => c.id == id);
          }
        }

        await localDS.saveCategories(homeId: homeId, categories: updatedCategories);
        LocalCacheNotifier.notify(homeId, 'categories');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleCategoryEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }

  Future<void> _handleHomeMemberEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    _debounceSync('home_members', () async {
      try {
        final userId = _client.auth.currentUser?.id;
        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        final targetUserId = (record['user_id'] ?? oldRecord['user_id']) as String?;
        final status = (record['status'] ?? oldRecord['status']) as String?;
        final deletedAt = record['deleted_at'] ?? oldRecord['deleted_at'];

        // If the current logged-in user is affected (revoked or deleted)
        if (userId != null && targetUserId == userId) {
          if (status == 'removed' || deletedAt != null || eventType == PostgresChangeEvent.delete) {
            // Member was revoked: trigger full homes sync to process revocation and redirect
            _ref.read(syncCoordinatorProvider.notifier).syncAll(homeId, force: true, targetDomain: 'homes');
            return;
          }
        }

        // Otherwise, sync members list to pull updated profiles
        _ref.read(syncCoordinatorProvider.notifier).syncAll(homeId, targetDomain: 'home_members');
      } catch (e, stack) {
        assert(() {
          print('RealtimeSyncService._handleHomeMemberEvent error: $e\n$stack');
          return true;
        }());
      }
    });
  }
}

/// Provider for [RealtimeSyncService]
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService(SupabaseService.client, ref);
  ref.onDispose(() => service.unsubscribe());
  return service;
});
