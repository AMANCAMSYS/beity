import 'dart:async';

import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/services/local_cache_notifier.dart';
import 'package:sawa/core/services/notification_service.dart';
import 'package:sawa/core/services/app_logger.dart';
import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/daos/units_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/data/models/item_template_model.dart';
import '../../../shopping_lists/data/repositories/shopping_list_repository.dart';
import '../../../shopping_lists/data/datasources/shopping_local_datasource.dart';
import '../../../shopping_lists/domain/entities/autocomplete_suggestion.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/sync_status.dart';

class OfflineAwareShoppingRepository implements ShoppingListRepository {
  static final DateTime _emptyServerSyncMarker =
      DateTime.fromMicrosecondsSinceEpoch(1);

  final ShoppingListRepository _remoteRepository;
  final OfflineQueueRepository _queueRepository;
  final ConnectivityRepository _connectivityRepository;
  final ShoppingLocalDataSource _localDataSource;
  final SyncService _syncService;
  final String? _homeId;

  OfflineAwareShoppingRepository({
    required ShoppingListRepository remoteRepository,
    required OfflineQueueRepository queueRepository,
    required ConnectivityRepository connectivityRepository,
    required ShoppingLocalDataSource localDataSource,
    required SyncService syncService,
    String? homeId,
  }) : _remoteRepository = remoteRepository,
       _queueRepository = queueRepository,
       _connectivityRepository = connectivityRepository,
       _localDataSource = localDataSource,
       _syncService = syncService,
       _homeId = homeId;

  Future<String> _getUserId() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) return user.id;
    return _localDataSource.getLastLoggedInUserId();
  }

  Future<bool> get _isOnline async {
    final status = await _connectivityRepository.getCurrentStatus();
    return status.isOnline;
  }

  void _notifyShoppingItems(String homeId, String listId) {
    LocalCacheNotifier.notify(homeId, 'shopping_items', listId: listId);
  }

  Future<void> _saveLocalListsWithState({
    required String homeId,
    required List<ShoppingListModel> lists,
    required String localState,
    String? syncError,
  }) {
    final localDataSource = _localDataSource;
    if (localDataSource is DriftShoppingLocalDataSource) {
      return localDataSource.saveShoppingListsWithLocalState(
        homeId: homeId,
        lists: lists,
        localState: localState,
        syncError: syncError,
      );
    }
    return localDataSource.saveShoppingListsStreamCache(
      homeId: homeId,
      lists: lists,
    );
  }

  Future<void> _saveLocalItemsWithState({
    required String listId,
    required List<ShoppingItemModel> items,
    required String localState,
    String? syncError,
  }) {
    final localDataSource = _localDataSource;
    if (localDataSource is DriftShoppingLocalDataSource) {
      return localDataSource.saveShoppingItemsWithLocalState(
        listId: listId,
        items: items,
        localState: localState,
        syncError: syncError,
      );
    }
    return localDataSource.saveShoppingItemsStreamCache(
      listId: listId,
      items: items,
    );
  }

  Future<void> _markLocalListDeleted({
    required String homeId,
    required String listId,
    required String localState,
  }) async {
    final localDataSource = _localDataSource;
    if (localDataSource is DriftShoppingLocalDataSource) {
      await localDataSource.softDeleteShoppingList(
        listId: listId,
        localState: localState,
      );
      return;
    }

    final current = await localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
    );
    await localDataSource.saveShoppingListsStreamCache(
      homeId: homeId,
      lists: current.where((list) => list.id != listId).toList(),
    );
  }

  Future<void> _markLocalItemDeleted({
    required String listId,
    required String itemId,
    required String localState,
  }) async {
    final localDataSource = _localDataSource;
    if (localDataSource is DriftShoppingLocalDataSource) {
      await localDataSource.softDeleteShoppingItem(
        itemId: itemId,
        localState: localState,
      );
      return;
    }

    final current = await localDataSource.getShoppingItemsStreamCache(
      listId: listId,
    );
    await localDataSource.saveShoppingItemsStreamCache(
      listId: listId,
      items: current.where((item) => item.id != itemId).toList(),
    );
  }

  Future<String> _listNameForNotification(String listId) async {
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final cachedLists = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      final cachedList = cachedLists.where((l) => l.id == listId).firstOrNull;
      if (cachedList != null && cachedList.name.isNotEmpty) {
        return cachedList.name;
      }
    }

    try {
      final remoteList = await _remoteRepository.getShoppingListById(
        listId: listId,
      );
      if (remoteList != null && remoteList.name.isNotEmpty) {
        return remoteList.name;
      }
    } catch (_) {}

    return 'list';
  }

  Future<void> _sendShoppingItemPush({
    required String eventType,
    required String homeId,
    required String listId,
    required String itemName,
    String? listName,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null || homeId.isEmpty || listId.isEmpty) return;

    await NotificationService.sendShoppingListNotification(
      homeId: homeId,
      actorId: user.id,
      referenceId: listId,
      eventType: eventType,
      context: {
        'item_name': itemName,
        'list_name': listName ?? await _listNameForNotification(listId),
      },
    );
  }

  Future<void> _sendShoppingListPush({
    required String eventType,
    required String homeId,
    required String listId,
    required String listName,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null || homeId.isEmpty || listId.isEmpty) return;

    await NotificationService.sendShoppingListNotification(
      homeId: homeId,
      actorId: user.id,
      referenceId: listId,
      eventType: eventType,
      context: {'list_name': listName},
    );
  }

  String _localStateForQueuedAction(ActionType actionType) {
    switch (actionType) {
      case ActionType.addItem:
      case ActionType.restoreItem:
        return localStatePendingCreate;
      case ActionType.deleteItem:
        return localStatePendingDelete;
      case ActionType.updateItem:
      case ActionType.updateQuantity:
      case ActionType.markPurchased:
        return localStatePendingUpdate;
      default:
        return localStatePendingUpdate;
    }
  }

  String? _baseUpdatedAt(DateTime? updatedAt, DateTime? createdAt) {
    final value = updatedAt ?? createdAt;
    return value?.toUtc().toIso8601String();
  }

  Future<void> _saveMergedListsPreservingQueueState({
    required String homeId,
    required List<ShoppingListModel> lists,
    required List<QueueEntry> queuedEntries,
  }) async {
    final queuedById = {
      for (final entry in queuedEntries.where(
        (entry) => entry.entityType == EntityType.shoppingList,
      ))
        entry.entityId: entry,
    };
    final syncedLists = <ShoppingListModel>[];
    final pendingByState = <String, List<ShoppingListModel>>{};

    for (final list in lists) {
      final queued = queuedById[list.id];
      if (queued == null) {
        syncedLists.add(list);
      } else {
        pendingByState
            .putIfAbsent(
              _localStateForQueuedAction(queued.actionType),
              () => [],
            )
            .add(list);
      }
    }

    await _saveLocalListsWithState(
      homeId: homeId,
      lists: syncedLists,
      localState: localStateSynced,
    );
    for (final entry in pendingByState.entries) {
      await _saveLocalListsWithState(
        homeId: homeId,
        lists: entry.value,
        localState: entry.key,
      );
    }
  }

  Future<void> _saveMergedItemsPreservingQueueState({
    required String listId,
    required List<ShoppingItemModel> items,
    required List<QueueEntry> queuedEntries,
  }) async {
    final queuedById = {
      for (final entry in queuedEntries.where(
        (entry) => entry.entityType == EntityType.shoppingItem,
      ))
        entry.entityId: entry,
    };
    final syncedItems = <ShoppingItemModel>[];
    final pendingByState = <String, List<ShoppingItemModel>>{};

    for (final item in items) {
      final queued = queuedById[item.id];
      if (queued == null) {
        syncedItems.add(item);
      } else {
        pendingByState
            .putIfAbsent(
              _localStateForQueuedAction(queued.actionType),
              () => [],
            )
            .add(item);
      }
    }

    await _saveLocalItemsWithState(
      listId: listId,
      items: syncedItems,
      localState: localStateSynced,
    );
    for (final entry in pendingByState.entries) {
      await _saveLocalItemsWithState(
        listId: listId,
        items: entry.value,
        localState: entry.key,
      );
    }
  }

  String _requireQueueHomeId([String? candidate]) {
    final resolved = candidate != null && candidate.isNotEmpty
        ? candidate
        : _homeId;
    if (resolved == null || resolved.isEmpty) {
      throw StateError('Missing homeId for offline shopping queue operation');
    }
    return resolved;
  }

  bool _isServerTimestampSet(DateTime time) {
    return time.millisecondsSinceEpoch > 0 || time.microsecondsSinceEpoch > 0;
  }

  DateTime _syncCheckpointFrom({
    required DateTime serverMaxUpdate,
    DateTime? localRecordMaxUpdate,
  }) {
    if (localRecordMaxUpdate != null &&
        _isServerTimestampSet(localRecordMaxUpdate)) {
      return localRecordMaxUpdate;
    }
    if (_isServerTimestampSet(serverMaxUpdate)) {
      return serverMaxUpdate;
    }
    return _emptyServerSyncMarker;
  }

  bool _isQueueEntryRetriable(QueueEntry entry) {
    if (entry.syncStatus == SyncStatus.pending ||
        entry.syncStatus == SyncStatus.syncing) {
      return true;
    }
    if (!entry.isFailed) return false;
    final isPermanent = entry.errorMessage?.startsWith('PERMANENT') ?? false;
    return entry.canRetry && !isPermanent;
  }

  Future<List<QueueEntry>> _queuedShoppingEntries(String homeId) async {
    try {
      final entries = await _queueRepository.getEntriesByHome(homeId);
      return entries
          .where(
            (entry) =>
                _isQueueEntryRetriable(entry) &&
                (entry.entityType == EntityType.shoppingList ||
                    entry.entityType == EntityType.shoppingItem),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  ShoppingListModel _applyQueuedListUpdate(
    ShoppingListModel list,
    Map<String, dynamic> payload,
  ) {
    final Object? description = payload.containsKey('type')
        ? payload['type'] as String?
        : payload.containsKey('description')
        ? payload['description'] as String?
        : shoppingFieldUnchanged;
    return list.copyWithModel(
      name: payload['title'] as String? ?? payload['name'] as String?,
      description: description,
      status: _parseListStatus(payload['status'] as String?),
    );
  }

  List<ShoppingListModel> _mergeQueuedShoppingLists(
    String homeId,
    List<ShoppingListModel> serverLists,
    List<ShoppingListModel> cachedLists,
    List<QueueEntry> queuedEntries,
  ) {
    final byId = <String, ShoppingListModel>{
      for (final list in serverLists) list.id: list,
    };
    final cachedById = <String, ShoppingListModel>{
      for (final list in cachedLists) list.id: list,
    };

    for (final entry in queuedEntries.where(
      (entry) => entry.entityType == EntityType.shoppingList,
    )) {
      final payload = entry.payload;
      switch (entry.actionType) {
        case ActionType.addItem:
        case ActionType.restoreItem:
          try {
            final localList = ShoppingListModel.fromJson(payload);
            if (localList.homeId == homeId) {
              byId[localList.id] = localList;
            }
          } catch (_) {
            final cached = cachedById[entry.entityId];
            if (cached != null) byId[entry.entityId] = cached;
          }
          break;
        case ActionType.updateItem:
        case ActionType.updateQuantity:
        case ActionType.markPurchased:
          final current = byId[entry.entityId] ?? cachedById[entry.entityId];
          if (current != null) {
            byId[entry.entityId] = _applyQueuedListUpdate(current, payload);
          }
          break;
        case ActionType.deleteItem:
          byId.remove(entry.entityId);
          break;
        default:
          break;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    return merged;
  }

  ShoppingItemModel _applyQueuedItemUpdate(
    ShoppingItemModel item,
    Map<String, dynamic> payload,
  ) {
    final status = payload['status'] as String?;
    return item.copyWithModel(
      name: payload['name'] as String?,
      quantity: (payload['quantity'] as num?)?.toDouble(),
      purchasedQuantity: (payload['purchased_quantity'] as num?)?.toDouble(),
      unitId: payload.containsKey('unit_id')
          ? payload['unit_id'] as String?
          : shoppingFieldUnchanged,
      categoryId: payload.containsKey('category_id')
          ? payload['category_id'] as String?
          : shoppingFieldUnchanged,
      price: payload.containsKey('estimated_price')
          ? (payload['estimated_price'] as num?)?.toDouble()
          : shoppingFieldUnchanged,
      notes: payload.containsKey('note')
          ? payload['note'] as String?
          : shoppingFieldUnchanged,
      isPurchased: status == null ? null : status == 'completed',
      purchasedAt: payload.containsKey('completed_at')
          ? (payload['completed_at'] == null
                ? null
                : DateTime.parse(payload['completed_at'] as String))
          : shoppingFieldUnchanged,
    );
  }

  List<ShoppingItemModel> _mergeQueuedShoppingItems(
    String listId,
    List<ShoppingItemModel> serverItems,
    List<ShoppingItemModel> cachedItems,
    List<QueueEntry> queuedEntries,
  ) {
    final byId = <String, ShoppingItemModel>{
      for (final item in serverItems) item.id: item,
    };
    final cachedById = <String, ShoppingItemModel>{
      for (final item in cachedItems) item.id: item,
    };

    for (final entry in queuedEntries.where(
      (entry) => entry.entityType == EntityType.shoppingItem,
    )) {
      final payload = entry.payload;
      final payloadListId = payload['list_id'] as String?;
      final cached = cachedById[entry.entityId];
      final targetListId = payloadListId ?? cached?.shoppingListId;
      if (targetListId != listId) continue;

      switch (entry.actionType) {
        case ActionType.addItem:
        case ActionType.restoreItem:
          try {
            final localItem = ShoppingItemModel.fromJson(payload);
            byId[localItem.id] = localItem;
          } catch (_) {
            if (cached != null) byId[entry.entityId] = cached;
          }
          break;
        case ActionType.updateItem:
        case ActionType.updateQuantity:
        case ActionType.markPurchased:
          final current = byId[entry.entityId] ?? cached;
          if (current != null) {
            byId[entry.entityId] = _applyQueuedItemUpdate(current, payload);
          }
          break;
        case ActionType.deleteItem:
          byId.remove(entry.entityId);
          break;
        default:
          break;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
    return merged;
  }

  DateTime _maxShoppingListTimestamp(List<ShoppingListModel> lists) {
    var maxTs = DateTime.fromMillisecondsSinceEpoch(0);
    for (final list in lists) {
      final updatedAt = list.updatedAt;
      final createdAt = list.createdAt;
      if (updatedAt != null && updatedAt.isAfter(maxTs)) maxTs = updatedAt;
      if (createdAt != null && createdAt.isAfter(maxTs)) maxTs = createdAt;
    }
    return maxTs;
  }

  DateTime _maxShoppingItemTimestamp(List<ShoppingItemModel> items) {
    var maxTs = DateTime.fromMillisecondsSinceEpoch(0);
    for (final item in items) {
      final updatedAt = item.updatedAt;
      final createdAt = item.createdAt;
      if (updatedAt != null && updatedAt.isAfter(maxTs)) maxTs = updatedAt;
      if (createdAt != null && createdAt.isAfter(maxTs)) maxTs = createdAt;
    }
    return maxTs;
  }

  // Shopping Lists
  @override
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) {
      return _remoteRepository.getShoppingLists(
        homeId: homeId,
        status: status,
        includeDeleted: true,
      );
    }

    // 1. Try cache first
    final cached = await _localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
      status: status,
    );
    if (cached.isNotEmpty) return cached;

    // 2. If cache is empty, fetch from server
    try {
      final serverLists = await _remoteRepository.getShoppingLists(
        homeId: homeId,
        includeDeleted: includeDeleted,
      );
      await _saveLocalListsWithState(
        homeId: homeId,
        lists: serverLists,
        localState: localStateSynced,
      );
      if (status != null) {
        return serverLists.where((l) => l.status.name == status).toList();
      }
      return serverLists;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ShoppingListModel?> getShoppingListById({
    required String listId,
  }) async {
    final homeId = _homeId;
    if (homeId != null) {
      final cached = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      for (final list in cached) {
        if (list.id == listId) return list;
      }
    }
    return _remoteRepository.getShoppingListById(listId: listId);
  }

  @override
  Future<ShoppingListModel> createShoppingList({
    String? id,
    required String homeId,
    required String name,
    String? description,
    String? icon,
  }) async {
    final effectiveId = const Uuid().v4();
    final userId = await _getUserId();

    final newList = ShoppingListModel(
      id: effectiveId,
      homeId: homeId,
      name: name,
      description: description,
      icon: icon ?? 'shopping_cart',
      status: ShoppingListStatus.active,
      createdBy: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Always optimistically update the local cache first!
    final currentLists = await _localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
    );
    final updatedLists = List<ShoppingListModel>.from(currentLists);
    if (!updatedLists.any((l) => l.id == effectiveId)) {
      updatedLists.add(newList);
    }
    await _saveLocalListsWithState(
      homeId: homeId,
      lists: updatedLists,
      localState: localStatePendingCreate,
    );
    LocalCacheNotifier.notify(homeId, 'shopping_lists');

    // 2. Perform online/offline operation
    if (await _isOnline) {
      try {
        final serverList = await _remoteRepository.createShoppingList(
          id: effectiveId,
          homeId: homeId,
          name: name,
          description: description,
          icon: icon,
        );
        // Replace temp model with actual server model to ensure timestamps are synced
        final refreshedLists = await _localDataSource
            .getShoppingListsStreamCache(homeId: homeId);
        final finalLists = refreshedLists
            .map((l) => l.id == effectiveId ? serverList : l)
            .toList();
        await _saveLocalListsWithState(
          homeId: homeId,
          lists: finalLists,
          localState: localStateSynced,
        );
        return serverList;
      } catch (_) {
        // Enqueue for offline sync if remote call fails
        await _queueRepository.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingList,
          entityId: effectiveId,
          homeId: homeId,
          payload: newList.toJson(),
        );
        return newList;
      }
    } else {
      // Queue for offline sync
      await _queueRepository.enqueueAction(
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingList,
        entityId: effectiveId,
        homeId: homeId,
        payload: newList.toJson(),
      );
      return newList;
    }
  }

  @override
  Future<ShoppingListModel> updateShoppingList({
    required String listId,
    String? name,
    String? description,
    String? status,
  }) async {
    ShoppingListModel? updatedList;
    String? resolvedHomeId = _homeId;
    final isOnline = await _isOnline;
    String? baseUpdatedAt;

    // 1. Always optimistically update the local cache first!
    // Try to find the homeId from cache if _homeId is null
    if (isOnline && (resolvedHomeId == null || resolvedHomeId.isEmpty)) {
      // Search all cached homes to find the list
      // This handles the case where activeHomeIdProvider hasn't been set
      try {
        final remoteList = await _remoteRepository.getShoppingListById(
          listId: listId,
        );
        if (remoteList != null) {
          resolvedHomeId = remoteList.homeId;
        }
      } catch (_) {}
    }

    if (resolvedHomeId != null && resolvedHomeId.isNotEmpty) {
      final currentLists = await _localDataSource.getShoppingListsStreamCache(
        homeId: resolvedHomeId,
      );
      final index = currentLists.indexWhere((l) => l.id == listId);
      if (index != -1) {
        final originalList = currentLists[index];
        baseUpdatedAt = _baseUpdatedAt(
          originalList.updatedAt,
          originalList.createdAt,
        );
        updatedList = ShoppingListModel(
          id: originalList.id,
          homeId: originalList.homeId,
          name: name ?? originalList.name,
          description: description ?? originalList.description,
          icon: originalList.icon,
          status: _parseListStatus(status) ?? originalList.status,
          createdBy: originalList.createdBy,
          createdAt: originalList.createdAt,
          updatedAt: DateTime.now(),
        );

        final updatedLists = List<ShoppingListModel>.from(currentLists);
        updatedLists[index] = updatedList;
        await _saveLocalListsWithState(
          homeId: resolvedHomeId,
          lists: updatedLists,
          localState: localStatePendingUpdate,
        );
        LocalCacheNotifier.notify(resolvedHomeId, 'shopping_lists');
      }
    }

    final payload = <String, dynamic>{};
    if (name != null) payload['title'] = name;
    if (description != null) payload['type'] = description;
    if (status != null) payload['status'] = status;
    if (baseUpdatedAt != null) payload['base_updated_at'] = baseUpdatedAt;

    // 2. Perform online/offline operation
    if (isOnline) {
      try {
        final serverList = await _remoteRepository.updateShoppingList(
          listId: listId,
          name: name,
          description: description,
          status: status,
        );
        if (resolvedHomeId != null && resolvedHomeId.isNotEmpty) {
          final current = await _localDataSource.getShoppingListsStreamCache(
            homeId: resolvedHomeId,
          );
          final updated = current
              .map((l) => l.id == listId ? serverList : l)
              .toList();
          await _saveLocalListsWithState(
            homeId: resolvedHomeId,
            lists: updated,
            localState: localStateSynced,
          );
        }
        if (resolvedHomeId != null &&
            resolvedHomeId.isNotEmpty &&
            status == 'completed') {
          unawaited(
            _sendShoppingListPush(
              eventType: 'list_completed',
              homeId: resolvedHomeId,
              listId: listId,
              listName: serverList.name,
            ),
          );
        }
        return serverList;
      } catch (_) {
        await _queueRepository.enqueueAction(
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingList,
          entityId: listId,
          homeId: _requireQueueHomeId(resolvedHomeId),
          payload: payload,
        );
      }
    } else {
      await _queueRepository.enqueueAction(
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingList,
        entityId: listId,
        homeId: _requireQueueHomeId(resolvedHomeId),
        payload: payload,
      );
    }

    if (updatedList != null) return updatedList;

    final userId = await _getUserId();
    return ShoppingListModel(
      id: listId,
      homeId: resolvedHomeId ?? '',
      name: name ?? '',
      description: description,
      status: _parseListStatus(status) ?? ShoppingListStatus.active,
      createdBy: userId,
      updatedAt: DateTime.now(),
    );
  }

  ShoppingListStatus? _parseListStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'active':
        return ShoppingListStatus.active;
      case 'completed':
        return ShoppingListStatus.completed;
      case 'archived':
        return ShoppingListStatus.archived;
      case 'cancelled':
        return ShoppingListStatus.cancelled;
      default:
        return ShoppingListStatus.active;
    }
  }

  @override
  Future<void> deleteShoppingList({required String listId}) async {
    // 1. Optimistically update local cache and notify UI instantly
    final homeId = _homeId;
    final queueHomeId = _requireQueueHomeId(homeId);
    String? baseUpdatedAt;
    if (homeId != null && homeId.isNotEmpty) {
      final current = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      final deletedList = current.where((l) => l.id == listId).firstOrNull;
      baseUpdatedAt = _baseUpdatedAt(
        deletedList?.updatedAt,
        deletedList?.createdAt,
      );
      await _markLocalListDeleted(
        homeId: homeId,
        listId: listId,
        localState: localStatePendingDelete,
      );
      LocalCacheNotifier.notify(homeId, 'shopping_lists');
    }

    // 2. Perform remote deletion or queue it for offline sync.
    if (await _isOnline) {
      try {
        await _remoteRepository.deleteShoppingList(listId: listId);
        if (homeId != null && homeId.isNotEmpty) {
          await _markLocalListDeleted(
            homeId: homeId,
            listId: listId,
            localState: localStateSynced,
          );
        }
        return;
      } catch (_) {
        // Fall through to queue for retry.
      }
    }

    final payload = <String, dynamic>{};
    if (baseUpdatedAt != null) {
      payload['base_updated_at'] = baseUpdatedAt;
    }

    await _queueRepository.enqueueAction(
      actionType: ActionType.deleteItem,
      entityType: EntityType.shoppingList,
      entityId: listId,
      homeId: queueHomeId,
      payload: payload,
    );
  }

  // Shopping Items
  @override
  Future<List<ShoppingItemModel>> getShoppingItems({
    required String listId,
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) {
      return _remoteRepository.getShoppingItems(
        listId: listId,
        includeDeleted: true,
      );
    }

    // 1. Try cache first
    final cached = await _localDataSource.getShoppingItemsStreamCache(
      listId: listId,
    );
    if (cached.isNotEmpty) return cached;

    // 2. If cache is empty, fetch from server
    try {
      final serverItems = await _remoteRepository.getShoppingItems(
        listId: listId,
        includeDeleted: includeDeleted,
      );
      await _saveLocalItemsWithState(
        listId: listId,
        items: serverItems,
        localState: localStateSynced,
      );
      return serverItems;
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<ShoppingListModel>> watchShoppingLists({
    required String homeId,
    String? status,
  }) {
    unawaited(_primeShoppingListsCache(homeId: homeId, status: status));
    return _localDataSource.watchShoppingListsStreamCache(
      homeId: homeId,
      status: status,
    );
  }

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItems({required String listId}) {
    unawaited(_primeShoppingItemsCache(listId: listId));
    return _localDataSource.watchShoppingItemsStreamCache(listId: listId);
  }

  Future<void> _primeShoppingListsCache({
    required String homeId,
    String? status,
  }) async {
    if (homeId.isEmpty) return;
    final cached = await _localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
      status: status,
    );
    if (cached.isNotEmpty) return;

    try {
      final serverLists = await _remoteRepository.getShoppingLists(
        homeId: homeId,
        status: status,
      );
      await _saveLocalListsWithState(
        homeId: homeId,
        lists: serverLists,
        localState: localStateSynced,
      );
      LocalCacheNotifier.notify(homeId, 'shopping_lists');
    } catch (_) {}
  }

  Future<void> _primeShoppingItemsCache({required String listId}) async {
    if (listId.isEmpty) return;
    final cached = await _localDataSource.getShoppingItemsStreamCache(
      listId: listId,
    );
    if (cached.isNotEmpty) return;

    try {
      final serverItems = await _remoteRepository.getShoppingItems(
        listId: listId,
      );
      await _saveLocalItemsWithState(
        listId: listId,
        items: serverItems,
        localState: localStateSynced,
      );
      final homeId = _homeId;
      if (homeId != null && homeId.isNotEmpty) {
        LocalCacheNotifier.notify(homeId, 'shopping_items', listId: listId);
      } else {
        LocalCacheNotifier.notify('', 'shopping_items', listId: listId);
      }
    } catch (_) {}
  }

  @override
  Future<Map<String, List<ShoppingItemModel>>> getShoppingItemsForLists({
    required List<String> listIds,
    bool includeDeleted = false,
  }) async {
    if (listIds.isEmpty) return {};
    if (includeDeleted) {
      return _remoteRepository.getShoppingItemsForLists(
        listIds: listIds,
        includeDeleted: true,
      );
    }

    final result = <String, List<ShoppingItemModel>>{};
    final missingListIds = <String>[];

    for (final listId in listIds) {
      final cached = await _localDataSource.getShoppingItemsStreamCache(
        listId: listId,
      );
      if (cached.isNotEmpty) {
        result[listId] = cached;
      } else {
        missingListIds.add(listId);
      }
    }

    if (missingListIds.isEmpty) return result;

    try {
      final remoteItems = await _remoteRepository.getShoppingItemsForLists(
        listIds: missingListIds,
        includeDeleted: includeDeleted,
      );
      for (final listId in missingListIds) {
        final items = remoteItems[listId] ?? <ShoppingItemModel>[];
        await _saveLocalItemsWithState(
          listId: listId,
          items: items,
          localState: localStateSynced,
        );
        result[listId] = items;
      }
    } catch (_) {
      for (final listId in missingListIds) {
        result[listId] = <ShoppingItemModel>[];
      }
    }

    return result;
  }

  @override
  Future<ShoppingItemModel?> getShoppingItemById({
    required String itemId,
  }) async {
    final homeId = _homeId;
    if (homeId != null) {
      final lists = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      for (final list in lists) {
        final items = await _localDataSource.getShoppingItemsStreamCache(
          listId: list.id,
        );
        for (final item in items) {
          if (item.id == itemId) return item;
        }
      }
    }
    return _remoteRepository.getShoppingItemById(itemId: itemId);
  }

  @override
  Future<ShoppingItemModel> createShoppingItem({
    String? id,
    required String listId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? currency,
    String? notes,
  }) async {
    final effectiveId = id ?? const Uuid().v4();
    final userId = await _getUserId();

    final newItem = ShoppingItemModel(
      id: effectiveId,
      shoppingListId: listId,
      name: name,
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
      price: price,
      currency: currency ?? 'SAR',
      notes: notes,
      createdBy: userId,
    );
    final isOnline = await _isOnline;
    if (!isOnline) {
      _requireQueueHomeId();
    }

    // 1. Always optimistically update the local cache first!
    final currentItems = await _localDataSource.getShoppingItemsStreamCache(
      listId: listId,
    );
    final updatedItems = List<ShoppingItemModel>.from(currentItems);
    if (!updatedItems.any((i) => i.id == effectiveId)) {
      updatedItems.add(newItem);
    }
    await _saveLocalItemsWithState(
      listId: listId,
      items: updatedItems,
      localState: localStatePendingCreate,
    );
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      _notifyShoppingItems(homeId, listId);
    }

    // 2. Perform online/offline operation
    if (isOnline) {
      try {
        final serverItem = await _remoteRepository.createShoppingItem(
          id: effectiveId,
          listId: listId,
          name: name,
          quantity: quantity,
          unitId: unitId,
          categoryId: categoryId,
          price: price,
          currency: currency,
          notes: notes,
        );
        // Replace temp model with actual server model to ensure timestamps are synced
        final refreshedItems = await _localDataSource
            .getShoppingItemsStreamCache(listId: listId);
        final finalItems = refreshedItems
            .map((i) => i.id == effectiveId ? serverItem : i)
            .toList();
        await _saveLocalItemsWithState(
          listId: listId,
          items: finalItems,
          localState: localStateSynced,
        );
        if (homeId != null && homeId.isNotEmpty) {
          unawaited(
            _sendShoppingItemPush(
              eventType: 'item_added',
              homeId: homeId,
              listId: listId,
              itemName: serverItem.name,
            ),
          );
        }
        return serverItem;
      } catch (e) {
        AppLogger.i('[ShoppingRepo] createShoppingItem remote error: $e');
        await _queueRepository.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: effectiveId,
          homeId: _requireQueueHomeId(),
          payload: newItem.toJson(),
        );
        return newItem;
      }
    } else {
      // Queue for offline sync
      await _queueRepository.enqueueAction(
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: effectiveId,
        homeId: _requireQueueHomeId(),
        payload: newItem.toJson(),
      );
      return newItem;
    }
  }

  @override
  Future<ShoppingItemModel> updateShoppingItem({
    required String itemId,
    String? name,
    double? quantity,
    double? purchasedQuantity,
    Object? unitId = shoppingFieldUnchanged,
    Object? categoryId = shoppingFieldUnchanged,
    Object? price = shoppingFieldUnchanged,
    Object? notes = shoppingFieldUnchanged,
  }) async {
    // 1. Find and optimistically update the local cache
    String targetListId = '';
    String? baseUpdatedAt;
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final lists = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      for (final list in lists) {
        final currentItems = await _localDataSource.getShoppingItemsStreamCache(
          listId: list.id,
        );
        final index = currentItems.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          targetListId = list.id;
          final original = currentItems[index];
          baseUpdatedAt = _baseUpdatedAt(
            original.updatedAt,
            original.createdAt,
          );
          final updated = ShoppingItemModel(
            id: original.id,
            shoppingListId: original.shoppingListId,
            name: name ?? original.name,
            quantity: quantity ?? original.quantity,
            purchasedQuantity: purchasedQuantity ?? original.purchasedQuantity,
            unitId: identical(unitId, shoppingFieldUnchanged)
                ? original.unitId
                : unitId as String?,
            categoryId: identical(categoryId, shoppingFieldUnchanged)
                ? original.categoryId
                : categoryId as String?,
            price: identical(price, shoppingFieldUnchanged)
                ? original.price
                : price as double?,
            currency: original.currency,
            notes: identical(notes, shoppingFieldUnchanged)
                ? original.notes
                : notes as String?,
            isPurchased: original.isPurchased,
            createdBy: original.createdBy,
            createdAt: original.createdAt,
            updatedAt: DateTime.now(),
          );

          final updatedItems = List<ShoppingItemModel>.from(currentItems);
          updatedItems[index] = updated;
          await _saveLocalItemsWithState(
            listId: list.id,
            items: updatedItems,
            localState: localStatePendingUpdate,
          );
          _notifyShoppingItems(homeId, list.id);
          break;
        }
      }
    }

    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (quantity != null) payload['quantity'] = quantity;
    if (purchasedQuantity != null) {
      payload['purchased_quantity'] = purchasedQuantity;
    }
    if (!identical(unitId, shoppingFieldUnchanged)) {
      payload['unit_id'] = unitId as String?;
    }
    if (!identical(categoryId, shoppingFieldUnchanged)) {
      payload['category_id'] = categoryId as String?;
    }
    if (!identical(price, shoppingFieldUnchanged)) {
      payload['estimated_price'] = price as double?;
    }
    if (!identical(notes, shoppingFieldUnchanged)) {
      payload['note'] = notes as String?;
    }
    if (baseUpdatedAt != null) payload['base_updated_at'] = baseUpdatedAt;

    // 2. Perform online/offline operation
    if (await _isOnline) {
      try {
        final serverItem = await _remoteRepository.updateShoppingItem(
          itemId: itemId,
          name: name,
          quantity: quantity,
          purchasedQuantity: purchasedQuantity,
          unitId: unitId,
          categoryId: categoryId,
          price: price,
          notes: notes,
        );
        if (targetListId.isNotEmpty) {
          final current = await _localDataSource.getShoppingItemsStreamCache(
            listId: targetListId,
          );
          final updated = current
              .map((i) => i.id == itemId ? serverItem : i)
              .toList();
          await _saveLocalItemsWithState(
            listId: targetListId,
            items: updated,
            localState: localStateSynced,
          );
          if (homeId != null && homeId.isNotEmpty) {
            unawaited(
              _sendShoppingItemPush(
                eventType: 'item_updated',
                homeId: homeId,
                listId: targetListId,
                itemName: serverItem.name,
              ),
            );
          }
        }
        return serverItem;
      } catch (_) {
        await _queueRepository.enqueueAction(
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: _requireQueueHomeId(),
          payload: payload,
        );
      }
    } else {
      await _queueRepository.enqueueAction(
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: _requireQueueHomeId(),
        payload: payload,
      );
    }

    if (targetListId.isNotEmpty) {
      final cachedItems = await _localDataSource.getShoppingItemsStreamCache(
        listId: targetListId,
      );
      final cached = cachedItems.where((i) => i.id == itemId).firstOrNull;
      if (cached != null) return cached;
    }

    final userId = await _getUserId();
    return ShoppingItemModel(
      id: itemId,
      shoppingListId: targetListId,
      name: name ?? '',
      quantity: quantity ?? 1,
      purchasedQuantity: purchasedQuantity ?? 0,
      unitId: identical(unitId, shoppingFieldUnchanged)
          ? null
          : unitId as String?,
      categoryId: identical(categoryId, shoppingFieldUnchanged)
          ? null
          : categoryId as String?,
      price: identical(price, shoppingFieldUnchanged) ? null : price as double?,
      notes: identical(notes, shoppingFieldUnchanged) ? null : notes as String?,
      createdBy: userId,
    );
  }

  @override
  Future<void> deleteShoppingItem({required String itemId}) async {
    // 1. Save item for potential rollback before optimistic delete
    ShoppingItemModel? savedItem;
    String? savedListId;
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final lists = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      for (final list in lists) {
        final currentItems = await _localDataSource.getShoppingItemsStreamCache(
          listId: list.id,
        );
        final item = currentItems.where((i) => i.id == itemId).firstOrNull;
        if (item != null) {
          savedItem = item;
          savedListId = list.id;
          // Optimistically remove from cache
          await _markLocalItemDeleted(
            listId: list.id,
            itemId: itemId,
            localState: localStatePendingDelete,
          );
          _notifyShoppingItems(homeId, list.id);
          break;
        }
      }
    }

    // 2. Perform background/remote deletion
    try {
      if (await _isOnline) {
        await _remoteRepository.deleteShoppingItem(itemId: itemId);
        if (savedListId != null) {
          await _markLocalItemDeleted(
            listId: savedListId,
            itemId: itemId,
            localState: localStateSynced,
          );
        }
      } else {
        await _queueRepository.enqueueAction(
          actionType: ActionType.deleteItem,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: _requireQueueHomeId(),
          payload: {
            if (savedItem != null)
              'base_updated_at': _baseUpdatedAt(
                savedItem.updatedAt,
                savedItem.createdAt,
              ),
          },
        );
      }
    } catch (_) {
      // If remote deletion fails, enqueue it for later retry
      // Note: We do NOT rollback the local deletion here, because we want the UI
      // to remain optimistically updated while the action is queued.
      await _queueRepository.enqueueAction(
        actionType: ActionType.deleteItem,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: _requireQueueHomeId(),
        payload: {
          if (savedItem != null)
            'base_updated_at': _baseUpdatedAt(
              savedItem.updatedAt,
              savedItem.createdAt,
            ),
        },
      );
    }
  }

  @override
  Future<ShoppingItemModel> restoreShoppingItem({
    required ShoppingItemModel item,
  }) async {
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final currentItems = await _localDataSource.getShoppingItemsStreamCache(
        listId: item.shoppingListId,
      );
      final updatedItems = List<ShoppingItemModel>.from(currentItems);
      final restoredItem = item.copyWithModel(
        deletedAt: null,
        updatedAt: DateTime.now(),
      );
      final index = updatedItems.indexWhere((i) => i.id == item.id);
      if (index == -1) {
        updatedItems.add(restoredItem);
      } else {
        updatedItems[index] = restoredItem;
      }
      await _saveLocalItemsWithState(
        listId: item.shoppingListId,
        items: updatedItems,
        localState: localStatePendingUpdate,
      );
      _notifyShoppingItems(homeId, item.shoppingListId);
    }

    if (await _isOnline) {
      try {
        final serverItem = await _remoteRepository.restoreShoppingItem(
          item: item,
        );
        if (homeId != null && homeId.isNotEmpty) {
          final current = await _localDataSource.getShoppingItemsStreamCache(
            listId: serverItem.shoppingListId,
          );
          final updated = current
              .map((i) => i.id == serverItem.id ? serverItem : i)
              .toList();
          await _saveLocalItemsWithState(
            listId: serverItem.shoppingListId,
            items: updated,
            localState: localStateSynced,
          );
          _notifyShoppingItems(homeId, serverItem.shoppingListId);
        }
        return serverItem;
      } catch (_) {}
    }

    await _queueRepository.enqueueAction(
      actionType: ActionType.restoreItem,
      entityType: EntityType.shoppingItem,
      entityId: item.id,
      homeId: _requireQueueHomeId(homeId),
      payload: {
        if (_baseUpdatedAt(item.updatedAt, item.createdAt) != null)
          'base_updated_at': _baseUpdatedAt(item.updatedAt, item.createdAt),
      },
    );

    return item.copyWithModel(deletedAt: null, updatedAt: DateTime.now());
  }

  @override
  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  }) async {
    // 1. Optimistically update the local cache
    String targetListId = '';
    String? baseUpdatedAt;
    final homeId = _homeId;
    var wasPurchasedBefore = false;
    String? listName;
    if (homeId != null && homeId.isNotEmpty) {
      final lists = await _localDataSource.getShoppingListsStreamCache(
        homeId: homeId,
      );
      for (final list in lists) {
        final currentItems = await _localDataSource.getShoppingItemsStreamCache(
          listId: list.id,
        );
        final index = currentItems.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          targetListId = list.id;
          listName = list.name;
          final original = currentItems[index];
          wasPurchasedBefore = original.isPurchased;
          baseUpdatedAt = _baseUpdatedAt(
            original.updatedAt,
            original.createdAt,
          );

          final userId = await _getUserId();
          final updated = ShoppingItemModel(
            id: original.id,
            shoppingListId: original.shoppingListId,
            name: original.name,
            quantity: original.quantity,
            purchasedQuantity: isPurchased ? original.quantity : 0.0,
            unitId: original.unitId,
            categoryId: original.categoryId,
            priority: original.priority,
            price: original.price,
            currency: original.currency,
            notes: original.notes,
            isPurchased: isPurchased,
            purchasedBy: isPurchased ? userId : null,
            purchasedAt: isPurchased ? DateTime.now() : null,
            createdBy: original.createdBy,
            createdAt: original.createdAt,
            updatedAt: DateTime.now(),
          );

          final updatedItems = List<ShoppingItemModel>.from(currentItems);
          updatedItems[index] = updated;
          await _saveLocalItemsWithState(
            listId: list.id,
            items: updatedItems,
            localState: localStatePendingUpdate,
          );
          _notifyShoppingItems(homeId, list.id);
          break;
        }
      }
    }

    final payload = <String, dynamic>{
      'status': isPurchased ? 'completed' : 'pending',
      'completed_at': isPurchased ? DateTime.now().toIso8601String() : null,
      if (!isPurchased) 'purchased_quantity': 0.0,
    };
    if (baseUpdatedAt != null) {
      payload['base_updated_at'] = baseUpdatedAt;
    }

    // 2. Perform online/offline operation
    if (await _isOnline) {
      try {
        final serverItem = await _remoteRepository.markItemPurchased(
          itemId: itemId,
          isPurchased: isPurchased,
        );
        if (targetListId.isNotEmpty) {
          final current = await _localDataSource.getShoppingItemsStreamCache(
            listId: targetListId,
          );
          final updated = current
              .map((i) => i.id == itemId ? serverItem : i)
              .toList();
          await _saveLocalItemsWithState(
            listId: targetListId,
            items: updated,
            localState: localStateSynced,
          );
          // Omit _notifyShoppingItems here because realtime service will notify it
          if (homeId != null &&
              homeId.isNotEmpty &&
              wasPurchasedBefore != isPurchased) {
            unawaited(
              _sendShoppingItemPush(
                eventType: isPurchased ? 'item_completed' : 'item_uncompleted',
                homeId: homeId,
                listId: targetListId,
                itemName: serverItem.name,
                listName: listName,
              ),
            );
          }
        }
        return serverItem;
      } catch (_) {
        await _queueRepository.enqueueAction(
          actionType: ActionType.markPurchased,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: _requireQueueHomeId(),
          payload: payload,
        );
      }
    } else {
      await _queueRepository.enqueueAction(
        actionType: ActionType.markPurchased,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: _requireQueueHomeId(),
        payload: payload,
      );
    }

    if (targetListId.isNotEmpty) {
      final cachedItems = await _localDataSource.getShoppingItemsStreamCache(
        listId: targetListId,
      );
      final cached = cachedItems.where((i) => i.id == itemId).firstOrNull;
      if (cached != null) return cached;
    }

    final userId = await _getUserId();
    return ShoppingItemModel(
      id: itemId,
      shoppingListId: targetListId,
      name: '',
      quantity: 1,
      isPurchased: isPurchased,
      createdBy: userId,
    );
  }

  @override
  Future<ShoppingItemModel> updateItemPurchaseState({
    required String itemId,
    required double purchasedQuantity,
  }) async {
    final homeId = _requireQueueHomeId();
    AppLogger.i(
      '[ShoppingRepo] updateItemPurchaseState: itemId=$itemId qty=$purchasedQuantity homeId=$homeId',
    );
    final userId = await _getUserId();
    ShoppingItemModel? optimisticItem;
    String? baseUpdatedAt;
    var targetListId = '';
    var wasPurchasedBefore = false;
    String? listName;

    final lists = await _localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
    );
    for (final list in lists) {
      final currentItems = await _localDataSource.getShoppingItemsStreamCache(
        listId: list.id,
      );
      final index = currentItems.indexWhere((i) => i.id == itemId);
      if (index == -1) continue;

      targetListId = list.id;
      listName = list.name;
      final original = currentItems[index];
      wasPurchasedBefore = original.isPurchased;
      baseUpdatedAt = _baseUpdatedAt(original.updatedAt, original.createdAt);
      final effectivePurchased = purchasedQuantity.clamp(
        0.0,
        original.quantity,
      );
      final isFullyPurchased = effectivePurchased >= original.quantity;
      optimisticItem = original.copyWithModel(
        purchasedQuantity: effectivePurchased,
        isPurchased: isFullyPurchased,
        purchasedBy: isFullyPurchased ? userId : null,
        purchasedAt: isFullyPurchased ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      final updatedItems = List<ShoppingItemModel>.from(currentItems);
      updatedItems[index] = optimisticItem;
      await _saveLocalItemsWithState(
        listId: list.id,
        items: updatedItems,
        localState: localStatePendingUpdate,
      );
      _notifyShoppingItems(homeId, list.id);
      break;
    }

    final effectivePurchased =
        optimisticItem?.purchasedQuantity ?? purchasedQuantity;
    final isFullyPurchased =
        optimisticItem != null && effectivePurchased >= optimisticItem.quantity;
    final payload = <String, dynamic>{
      'purchased_quantity': effectivePurchased,
      'status': isFullyPurchased ? 'completed' : 'pending',
      'completed_at': isFullyPurchased
          ? DateTime.now().toIso8601String()
          : null,
      'completed_by': isFullyPurchased ? userId : null,
    };
    if (baseUpdatedAt != null) {
      payload['base_updated_at'] = baseUpdatedAt;
    }

    if (await _isOnline) {
      try {
        final serverItem = await _remoteRepository.updateItemPurchaseState(
          itemId: itemId,
          purchasedQuantity: effectivePurchased,
        );
        if (targetListId.isNotEmpty) {
          final current = await _localDataSource.getShoppingItemsStreamCache(
            listId: targetListId,
          );
          final updated = current
              .map((i) => i.id == itemId ? serverItem : i)
              .toList();
          await _saveLocalItemsWithState(
            listId: targetListId,
            items: updated,
            localState: localStateSynced,
          );
          _notifyShoppingItems(homeId, targetListId);
          if (wasPurchasedBefore != serverItem.isPurchased) {
            unawaited(
              _sendShoppingItemPush(
                eventType: serverItem.isPurchased
                    ? 'item_completed'
                    : 'item_uncompleted',
                homeId: homeId,
                listId: targetListId,
                itemName: serverItem.name,
                listName: listName,
              ),
            );
          }
        }
        return serverItem;
      } catch (_) {
        await _queueRepository.enqueueAction(
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: homeId,
          payload: payload,
        );
      }
    } else {
      await _queueRepository.enqueueAction(
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: homeId,
        payload: payload,
      );
    }

    if (optimisticItem != null) return optimisticItem;

    return ShoppingItemModel(
      id: itemId,
      shoppingListId: targetListId,
      name: '',
      quantity: 1,
      purchasedQuantity: effectivePurchased,
      isPurchased: isFullyPurchased,
      purchasedBy: isFullyPurchased ? userId : null,
      purchasedAt: isFullyPurchased ? DateTime.now() : null,
      createdBy: userId,
    );
  }

  @override
  Future<List<ShoppingItemModel>> getPurchaseHistory({
    required String homeId,
    int limit = 50,
  }) {
    return _remoteRepository.getPurchaseHistory(homeId: homeId, limit: limit);
  }

  // Item Templates
  @override
  Future<List<ItemTemplateModel>> getItemTemplates({
    required String homeId,
  }) async {
    final cached = await _localDataSource.getItemTemplates(homeId: homeId);
    if (cached.isNotEmpty) return cached;

    try {
      final templates = await _remoteRepository.getItemTemplates(
        homeId: homeId,
      );
      await _localDataSource.saveItemTemplates(
        homeId: homeId,
        templates: templates,
      );
      return templates;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ItemTemplateModel> createItemTemplate({
    required String homeId,
    required String name,
    double defaultQuantity = 1,
    String? defaultUnitId,
    String? defaultCategoryId,
  }) {
    return _remoteRepository.createItemTemplate(
      homeId: homeId,
      name: name,
      defaultQuantity: defaultQuantity,
      defaultUnitId: defaultUnitId,
      defaultCategoryId: defaultCategoryId,
    );
  }

  @override
  Future<void> incrementTemplateUsage({required String templateId}) {
    return _remoteRepository.incrementTemplateUsage(templateId: templateId);
  }

  @override
  Stream<List<ItemTemplateModel>> watchItemTemplates({
    required String homeId,
  }) async* {
    // 1. Emit cached templates instantly
    final cached = await _localDataSource.getItemTemplates(homeId: homeId);
    yield cached;

    // 2. If cache is empty, fetch from server and populate cache
    if (cached.isEmpty) {
      try {
        final templates = await _remoteRepository.getItemTemplates(
          homeId: homeId,
        );
        await _localDataSource.saveItemTemplates(
          homeId: homeId,
          templates: templates,
        );
        yield templates;
      } catch (_) {
        // Server fetch failed — stream will still update via LocalCacheNotifier
      }
    }

    // 3. React to local cache updates
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'item_templates') {
        yield await _localDataSource.getItemTemplates(homeId: homeId);
      }
    }
  }

  // Autocomplete suggestions
  @override
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions({
    required String homeId,
    required String query,
    int limit = 10,
  }) async {
    final localSuggestions = await _getLocalAutocompleteSuggestions(
      homeId: homeId,
      query: query,
      limit: limit,
    );
    if (localSuggestions.isNotEmpty || !(await _isOnline)) {
      return localSuggestions;
    }

    try {
      return await _remoteRepository.getAutocompleteSuggestions(
        homeId: homeId,
        query: query,
        limit: limit,
      );
    } catch (_) {
      return localSuggestions;
    }
  }

  Future<List<AutocompleteSuggestion>> _getLocalAutocompleteSuggestions({
    required String homeId,
    required String query,
    required int limit,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    final unitMap = await _getLocalUnitMap();
    final suggestions = <AutocompleteSuggestion>[];
    final seenNames = <String>{};

    final templates = await _localDataSource.getItemTemplates(homeId: homeId);
    final matchingTemplates = templates.where((template) {
      return template.name.toLowerCase().contains(normalizedQuery);
    }).toList()..sort((a, b) => b.usageCount.compareTo(a.usageCount));

    for (final template in matchingTemplates) {
      if (!seenNames.add(template.name.toLowerCase())) continue;
      suggestions.add(
        AutocompleteSuggestion(
          name: template.name,
          quantity: template.defaultQuantity,
          unitName: template.defaultUnitId == null
              ? null
              : unitMap[template.defaultUnitId],
          sourceId: template.id,
          isTemplate: true,
        ),
      );
      if (suggestions.length >= limit) return suggestions;
    }

    final lists = await _localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
    );
    for (final list in lists) {
      final items = await _localDataSource.getShoppingItemsStreamCache(
        listId: list.id,
      );
      for (final item in items) {
        if (!item.name.toLowerCase().contains(normalizedQuery)) continue;
        if (!seenNames.add(item.name.toLowerCase())) continue;

        suggestions.add(
          AutocompleteSuggestion(
            name: item.name,
            quantity: item.quantity,
            unitName: item.unitId == null ? null : unitMap[item.unitId],
            isTemplate: false,
          ),
        );
        if (suggestions.length >= limit) return suggestions;
      }
    }

    return suggestions;
  }

  Future<Map<String, String>> _getLocalUnitMap() async {
    final units = await UnitsDao(LocalDatabaseService.instance).getUnits();
    return {
      for (final unit in units)
        unit.id: unit.symbol.isNotEmpty
            ? '${unit.name} (${unit.symbol})'
            : unit.name,
    };
  }

  @override
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
  }) async {
    if (!(await _isOnline)) return;

    try {
      await _remoteRepository.syncTemplateOnAdd(
        homeId: homeId,
        name: name,
        quantity: quantity,
        unitId: unitId,
        categoryId: categoryId,
      );
    } catch (_) {}
  }

  @override
  Future<void> syncShoppingWithServer(String homeId) async {
    try {
      final serverUpdates = await _syncService.getServerLastUpdates(homeId);
      final queuedEntries = await _queuedShoppingEntries(homeId);

      // 1. Sync Shopping Lists if server is newer or the empty state was never synced
      final serverListsMaxUpdate = serverUpdates['shopping_lists'];
      if (serverListsMaxUpdate != null) {
        final localSyncTime = await _syncService.getLocalSyncTimeAsync(
          homeId,
          'shopping_lists',
        );
        final cachedLists = await _localDataSource.getShoppingListsStreamCache(
          homeId: homeId,
        );
        final hasSyncedListsBefore = await _syncService.isInitialSyncDone(
          homeId,
          'shopping_lists',
        );
        final needsInitialEmptyListSync =
            !hasSyncedListsBefore && cachedLists.isEmpty;

        if (needsInitialEmptyListSync ||
            serverListsMaxUpdate.isAfter(localSyncTime)) {
          final serverLists = await _remoteRepository.getShoppingLists(
            homeId: homeId,
            includeDeleted: true,
          );
          final lists = _mergeQueuedShoppingLists(
            homeId,
            serverLists,
            cachedLists,
            queuedEntries,
          );

          // Save to local cache
          await _saveMergedListsPreservingQueueState(
            homeId: homeId,
            lists: lists,
            queuedEntries: queuedEntries,
          );

          // Update local sync time
          final maxTs = _maxShoppingListTimestamp(serverLists);
          await _syncService.updateLocalSyncTime(
            homeId,
            'shopping_lists',
            _syncCheckpointFrom(
              serverMaxUpdate: serverListsMaxUpdate,
              localRecordMaxUpdate: maxTs,
            ),
          );

          // Notify reactive list stream
          LocalCacheNotifier.notify(homeId, 'shopping_lists');
        }
      }

      // 2. Sync Shopping Items if server is newer or the empty state was never synced
      final serverItemsMaxUpdate = serverUpdates['shopping_items'];
      if (serverItemsMaxUpdate != null) {
        final localSyncTime = await _syncService.getLocalSyncTimeAsync(
          homeId,
          'shopping_items',
        );
        final hasSyncedItemsBefore = await _syncService.isInitialSyncDone(
          homeId,
          'shopping_items',
        );
        final lists = await _localDataSource.getShoppingListsStreamCache(
          homeId: homeId,
        );

        bool isCacheEmpty = true;
        for (final list in lists) {
          final cachedItems = await _localDataSource
              .getShoppingItemsStreamCache(listId: list.id);
          if (cachedItems.isNotEmpty) {
            isCacheEmpty = false;
            break;
          }
        }
        final needsInitialEmptyItemsSync =
            !hasSyncedItemsBefore && isCacheEmpty;

        if (needsInitialEmptyItemsSync ||
            serverItemsMaxUpdate.isAfter(localSyncTime)) {
          // Load all active lists in the home
          final lists = await _localDataSource.getShoppingListsStreamCache(
            homeId: homeId,
          );

          // Fetch items for all lists in parallel and cache them
          final listIds = lists.map((list) => list.id).toList();
          Map<String, List<ShoppingItemModel>> serverItemsByList;
          if (listIds.isEmpty) {
            serverItemsByList = <String, List<ShoppingItemModel>>{};
          } else {
            try {
              serverItemsByList = await _remoteRepository
                  .getShoppingItemsForLists(
                    listIds: listIds,
                    includeDeleted: true,
                  );
            } catch (_) {
              serverItemsByList = {
                for (final listId in listIds) listId: <ShoppingItemModel>[],
              };
            }
          }

          final syncedItemBatches = <List<ShoppingItemModel>>[];
          for (final list in lists) {
            final serverItems =
                serverItemsByList[list.id] ?? <ShoppingItemModel>[];
            final cachedItems = await _localDataSource
                .getShoppingItemsStreamCache(listId: list.id);
            final items = _mergeQueuedShoppingItems(
              list.id,
              serverItems,
              cachedItems,
              queuedEntries,
            );
            await _saveMergedItemsPreservingQueueState(
              listId: list.id,
              items: items,
              queuedEntries: queuedEntries,
            );
            syncedItemBatches.add(serverItems);
          }

          // Update local sync time
          final itemRecordMax = syncedItemBatches
              .expand((items) => items)
              .fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0), (
                maxTs,
                item,
              ) {
                final itemMax = _maxShoppingItemTimestamp([item]);
                return itemMax.isAfter(maxTs) ? itemMax : maxTs;
              });
          await _syncService.updateLocalSyncTime(
            homeId,
            'shopping_items',
            _syncCheckpointFrom(
              serverMaxUpdate: serverItemsMaxUpdate,
              localRecordMaxUpdate: itemRecordMax,
            ),
          );

          // Notify reactive items stream
          LocalCacheNotifier.notify(homeId, 'shopping_items');
        }
      }

      // 3. Sync Item Templates
      try {
        final templates = await _remoteRepository.getItemTemplates(
          homeId: homeId,
        );
        await _localDataSource.saveItemTemplates(
          homeId: homeId,
          templates: templates,
        );
        LocalCacheNotifier.notify(homeId, 'item_templates');
      } catch (_) {}
    } catch (_) {
      rethrow;
    }
  }
}
