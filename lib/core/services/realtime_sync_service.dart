import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_cache_notifier.dart';
import 'supabase_service.dart';
import 'sync_coordinator.dart';
import 'sync_service.dart';
import '../../features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../features/shopping_lists/data/datasources/shopping_local_datasource.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/expenses/presentation/providers/expense_providers.dart';
import '../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../features/categories/presentation/providers/categories_provider.dart';
import '../../features/categories/data/datasources/category_local_datasource.dart';
import '../../features/shopping_lists/data/models/shopping_list_model.dart';
import '../../features/shopping_lists/data/models/shopping_item_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/inventory/data/models/inventory_item_model.dart';
import '../../features/categories/data/models/category_model.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../local_database/daos/notifications_dao.dart';
import '../local_database/app_database.dart';
import '../local_database/local_database_service.dart';
import '../local_database/local_model_mappers.dart';
import 'app_logger.dart';

class RealtimeSyncService {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _channel;
  String? _currentHomeId;
  final List<RealtimeEvent> _buffer = <RealtimeEvent>[];
  bool _isBuffering = false;
  bool _isFlushingBuffer = false;

  final Map<String, Timer> _debounceTimers = {};

  RealtimeSyncService(this._client, this._ref);

  bool get isBuffering => _isBuffering;

  int get bufferedEventCount => _buffer.length;

  int get debounceTimerCount => _debounceTimers.length;

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final homeId = _currentHomeId;
    if (homeId == null || homeId.isEmpty) return;

    _isBuffering = false;
    _buffer.clear();
    unsubscribe();
    _initChannel(homeId);
  }

  void initBuffered(String homeId) {
    if (homeId.isEmpty) return;
    if (_currentHomeId == homeId && _isBuffering) return;
    _buffer.clear();
    _initChannel(homeId);
    _isBuffering = true;
  }

  Future<void> flushBuffer() async {
    final pending = List<RealtimeEvent>.from(_buffer);
    _buffer.clear();
    _isBuffering = false;
    _isFlushingBuffer = true;
    try {
      for (final event in pending) {
        if (event.homeId != _currentHomeId) continue;
        await _applyRealtimeEvent(event);
      }
    } finally {
      _isFlushingBuffer = false;
    }
  }

  void init(String homeId) {
    _isBuffering = false;
    _buffer.clear();
    _initChannel(homeId);
  }

  void _initChannel(String homeId) {
    if (homeId.isEmpty) return;
    if (_currentHomeId == homeId) return;

    unsubscribe();

    _currentHomeId = homeId;

    _channel = _client.channel('realtime_sync:$homeId');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_lists',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('shopping_lists', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_items',
      callback: (payload) => _receiveRealtimeEvent('shopping_items', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('tasks', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'expenses',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('expenses', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'inventory_items',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('inventory_items', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'categories',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('categories', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'home_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('home_members', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => _receiveRealtimeEvent('notifications', payload),
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
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ removeChannel failed: $e');
      }
      _channel = null;
    }

    _currentHomeId = null;
    _isBuffering = false;
    _buffer.clear();
  }

  void _receiveRealtimeEvent(String table, PostgresChangePayload payload) {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    final event = RealtimeEvent(homeId: homeId, table: table, payload: payload);
    if (_isBuffering) {
      _buffer.add(event);
      return;
    }

    _applyRealtimeEvent(event).catchError((e) {
      AppLogger.i('[RealtimeSync] ❌ Error in $table handler: $e');
    });
  }

  Future<void> _applyRealtimeEvent(RealtimeEvent event) async {
    switch (event.table) {
      case 'shopping_lists':
        return _handleShoppingListEvent(event.payload);
      case 'shopping_items':
        return _handleShoppingItemEvent(event.payload);
      case 'tasks':
        return _handleTaskEvent(event.payload);
      case 'expenses':
        return _handleExpenseEvent(event.payload);
      case 'inventory_items':
        return _handleInventoryItemEvent(event.payload);
      case 'categories':
        return _handleCategoryEvent(event.payload);
      case 'home_members':
        return _handleHomeMemberEvent(event.payload);
      case 'notifications':
        return _handleNotificationEvent(event.payload);
    }
  }

  Future<void> _debounceSync(
    String domain,
    Future<void> Function() action,
  ) async {
    _debounceTimers[domain]?.cancel();
    if (_isFlushingBuffer) {
      _debounceTimers.remove(domain);
      await action();
      return;
    }

    _debounceTimers[domain] = Timer(
      const Duration(milliseconds: 800),
      () async {
        try {
          await action();
        } catch (e) {
          AppLogger.i('[RealtimeSync] ❌ Debounce error ($domain): $e');
        }
      },
    );
  }

  // MARK: - Event Handlers

  Future<void> _handleShoppingListEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    try {
      final localDS = _ref.read(shoppingLocalDataSourceProvider);
      final currentLists = await localDS.getShoppingListsStreamCache(
        homeId: homeId,
      );
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
          if (updatedList.deletedAt != null) {
            if (localDS is DriftShoppingLocalDataSource) {
              await localDS.softDeleteShoppingList(
                listId: updatedList.id,
                deletedAt: updatedList.deletedAt,
                localState: localStateSynced,
              );
            }
            updatedLists.removeWhere((l) => l.id == updatedList.id);
          } else if (index != -1) {
            updatedLists[index] = updatedList;
          } else {
            updatedLists.add(updatedList);
          }
        }
      } else if (eventType == PostgresChangeEvent.delete) {
        final id = oldRecord['id'] as String?;
        if (id != null) {
          if (localDS is DriftShoppingLocalDataSource) {
            await localDS.softDeleteShoppingList(
              listId: id,
              deletedAt: DateTime.now(),
              localState: localStateSynced,
            );
          }
          updatedLists.removeWhere((l) => l.id == id);
        }
      }

      await localDS.saveShoppingListsStreamCache(
        homeId: homeId,
        lists: updatedLists,
      );
      LocalCacheNotifier.notify(homeId, 'shopping_lists');

      // Bump localSyncTime so periodic sync won't overwrite this Realtime data
      final updatedAtStr = record['updated_at'] as String?;
      if (updatedAtStr != null) {
        final updatedAt = DateTime.tryParse(updatedAtStr);
        if (updatedAt != null) {
          final syncService = _ref.read(syncServiceProvider);
          await syncService.updateLocalSyncTime(
            homeId,
            'shopping_lists',
            updatedAt,
          );
        }
      }
    } catch (e) {
      AppLogger.i('[RealtimeSync] ❌ shopping_lists error: $e');
    }
  }

  Future<void> _handleShoppingItemEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    final record = payload.newRecord;
    final oldRecord = payload.oldRecord;
    final listId = (record['list_id'] ?? oldRecord['list_id']) as String?;
    if (listId == null) return;

    final localDS = _ref.read(shoppingLocalDataSourceProvider);
    final recordHomeId = (record['home_id'] ?? oldRecord['home_id']) as String?;
    var belongsToHome = recordHomeId == homeId;
    if (!belongsToHome) {
      final currentLists = await localDS.getShoppingListsStreamCache(
        homeId: homeId,
      );
      belongsToHome = currentLists.any((l) => l.id == listId);
    }
    if (!belongsToHome) {
      _ref
          .read(syncCoordinatorProvider.notifier)
          .syncAll(homeId, targetDomain: 'shopping');
      return;
    }

    await _debounceSync('shopping_items_$listId', () async {
      try {
        final currentItems = await localDS.getShoppingItemsStreamCache(
          listId: listId,
        );
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
            final index = updatedItems.indexWhere(
              (i) => i.id == updatedItem.id,
            );
            if (updatedItem.deletedAt != null) {
              if (localDS is DriftShoppingLocalDataSource) {
                await localDS.softDeleteShoppingItem(
                  itemId: updatedItem.id,
                  deletedAt: updatedItem.deletedAt,
                  localState: localStateSynced,
                );
              }
              updatedItems.removeWhere((i) => i.id == updatedItem.id);
            } else if (index != -1) {
              updatedItems[index] = updatedItem;
            } else {
              updatedItems.add(updatedItem);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            if (localDS is DriftShoppingLocalDataSource) {
              await localDS.softDeleteShoppingItem(
                itemId: id,
                deletedAt: DateTime.now(),
                localState: localStateSynced,
              );
            }
            updatedItems.removeWhere((i) => i.id == id);
          }
        }

        // Use Drift-aware save with homeId from payload
        if (localDS is DriftShoppingLocalDataSource) {
          await localDS.saveShoppingItemsWithLocalState(
            listId: listId,
            items: updatedItems,
            localState: localStateSynced,
            homeId: recordHomeId ?? homeId,
          );
        } else {
          await localDS.saveShoppingItemsStreamCache(
            listId: listId,
            items: updatedItems,
          );
        }

        // Detect purchase state changes for notification
        final newStatus = record['status'] as String?;
        final oldStatus = oldRecord['status'] as String?;
        final itemName = record['name'] as String?;
        final completedBy = record['completed_by'] as String?;

        if (newStatus != null && newStatus != oldStatus && itemName != null) {
          final isPurchased = newStatus == 'completed';
          LocalCacheNotifier.notifyPurchase(
            homeId,
            listId: listId,
            itemName: itemName,
            purchaserId: completedBy,
            isPurchased: isPurchased,
          );
        } else {
          LocalCacheNotifier.notify(homeId, 'shopping_items', listId: listId);
        }

        // Bump localSyncTime so periodic sync won't overwrite this Realtime data
        final updatedAtStr = record['updated_at'] as String?;
        if (updatedAtStr != null) {
          final updatedAt = DateTime.tryParse(updatedAtStr);
          if (updatedAt != null) {
            final syncService = _ref.read(syncServiceProvider);
            await syncService.updateLocalSyncTime(
              homeId,
              'shopping_items',
              updatedAt,
            );
          }
        }
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ shopping_items error: $e');
      }
    });
  }

  Future<void> _handleNotificationEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    final userId = _client.auth.currentUser?.id;
    if (homeId == null || userId == null) return;

    try {
      final record = payload.newRecord;
      final oldRecord = payload.oldRecord;
      final targetUserId =
          (record['user_id'] ?? oldRecord['user_id']) as String?;
      if (targetUserId != userId) return;

      final dao = NotificationsDao(LocalDatabaseService.instance);
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = oldRecord['id'] as String?;
        if (id != null) {
          await dao.deleteById(id);
        }
      } else if (record.isNotEmpty) {
        final notification = NotificationModel.fromJson(record);
        await dao.upsertNotifications([notification.toLocalRow()]);
      }

      LocalCacheNotifier.notify(homeId, 'notifications');
    } catch (e) {
      AppLogger.i('[RealtimeSync] ❌ notifications error: $e');
    }
  }

  Future<void> _handleTaskEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    await _debounceSync('tasks', () async {
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
            final index = updatedTasks.indexWhere(
              (t) => t.id == updatedTask.id,
            );
            if (index != -1) {
              if (updatedTask.deletedAt != null ||
                  updatedTask.archivedAt != null) {
                updatedTasks.removeAt(index);
              } else {
                updatedTasks[index] = updatedTask;
              }
            } else if (updatedTask.deletedAt == null &&
                updatedTask.archivedAt == null) {
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
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ tasks error: $e');
      }
    });
  }

  Future<void> _handleExpenseEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    await _debounceSync('expenses', () async {
      try {
        final localDS = _ref.read(expenseLocalDataSourceProvider);
        final currentExpenses = await localDS.getExpensesStreamCache(
          homeId: homeId,
        );
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
            final index = updatedExpenses.indexWhere(
              (e) => e.id == updatedExpense.id,
            );
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

        await localDS.saveExpensesStreamCache(
          homeId: homeId,
          expenses: updatedExpenses,
        );
        LocalCacheNotifier.notify(homeId, 'expenses');
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ expenses error: $e');
      }
    });
  }

  Future<void> _handleInventoryItemEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    await _debounceSync('inventory', () async {
      try {
        final localDS = _ref.read(inventoryLocalDataSourceProvider);
        final currentItems = await localDS.getInventoryItemsStreamCache(
          homeId: homeId,
        );
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
            final index = updatedItems.indexWhere(
              (i) => i.id == updatedItem.id,
            );
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

        await localDS.saveInventoryItemsStreamCache(
          homeId: homeId,
          items: updatedItems,
        );
        LocalCacheNotifier.notify(homeId, 'inventory_items');
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ inventory error: $e');
      }
    });
  }

  Future<void> _handleCategoryEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    await _debounceSync('categories', () async {
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
            final index = updatedCategories.indexWhere(
              (c) => c.id == updatedCategory.id,
            );
            if (updatedCategory.deletedAt != null) {
              if (localDS is DriftCategoryLocalDataSource) {
                await localDS.softDeleteCategory(
                  categoryId: updatedCategory.id,
                  deletedAt: updatedCategory.deletedAt,
                );
              }
              updatedCategories.removeWhere((c) => c.id == updatedCategory.id);
            } else if (index != -1) {
              updatedCategories[index] = updatedCategory;
            } else {
              updatedCategories.add(updatedCategory);
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = oldRecord['id'] as String?;
          if (id != null) {
            if (localDS is DriftCategoryLocalDataSource) {
              await localDS.softDeleteCategory(
                categoryId: id,
                deletedAt: DateTime.now(),
              );
            }
            updatedCategories.removeWhere((c) => c.id == id);
          }
        }

        await localDS.saveCategories(
          homeId: homeId,
          categories: updatedCategories,
        );
        LocalCacheNotifier.notify(homeId, 'categories');
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ categories error: $e');
      }
    });
  }

  Future<void> _handleHomeMemberEvent(PostgresChangePayload payload) async {
    final homeId = _currentHomeId;
    if (homeId == null) return;

    await _debounceSync('home_members', () async {
      try {
        final userId = _client.auth.currentUser?.id;
        final record = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final eventType = payload.eventType;

        final targetUserId =
            (record['user_id'] ?? oldRecord['user_id']) as String?;
        final status = (record['status'] ?? oldRecord['status']) as String?;
        final deletedAt = record['deleted_at'] ?? oldRecord['deleted_at'];

        if (userId != null && targetUserId == userId) {
          if (status == 'removed' ||
              deletedAt != null ||
              eventType == PostgresChangeEvent.delete) {
            _ref
                .read(syncCoordinatorProvider.notifier)
                .syncAll(homeId, force: true, targetDomain: 'homes');
            return;
          }
        }

        _ref
            .read(syncCoordinatorProvider.notifier)
            .syncAll(homeId, targetDomain: 'home_members');
      } catch (e) {
        AppLogger.i('[RealtimeSync] ❌ home_members error: $e');
      }
    });
  }
}

@visibleForTesting
class RealtimeEvent {
  final String homeId;
  final String table;
  final PostgresChangePayload payload;

  const RealtimeEvent({
    required this.homeId,
    required this.table,
    required this.payload,
  });
}

/// Provider for [RealtimeSyncService]
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService(SupabaseService.client, ref);
  ref.onDispose(() => service.unsubscribe());
  return service;
});
