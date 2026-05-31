import 'package:beity/core/services/sync_service.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/core/services/local_cache_notifier.dart';
import 'package:beity/features/shopping_lists/domain/entities/shopping_list.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/data/models/item_template_model.dart';
import '../../../shopping_lists/data/repositories/shopping_list_repository.dart';
import '../../../shopping_lists/data/datasources/shopping_local_datasource.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import 'package:uuid/uuid.dart';


class OfflineAwareShoppingRepository implements ShoppingListRepository {
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
  })  : _remoteRepository = remoteRepository,
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

  // Shopping Lists
  @override
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
  }) async {
    // Return cached lists instantly (100% Local-First Single Source of Truth)
    // No remote fetching is triggered from getters. Initial sync is handled solely by SyncCoordinator.
    return _localDataSource.getShoppingListsStreamCache(
      homeId: homeId,
      status: status,
    );
  }

  @override
  Future<ShoppingListModel?> getShoppingListById({required String listId}) async {
    final homeId = _homeId;
    if (homeId != null) {
      final cached = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      for (final list in cached) {
        if (list.id == listId) return list;
      }
    }
    return _remoteRepository.getShoppingListById(listId: listId);
  }

  @override
  Future<ShoppingListModel> createShoppingList({
    required String homeId,
    required String name,
    String? description,
    String? icon,
  }) async {
    if (!(await _isOnline)) {
      throw Exception('يجب توفر اتصال بالإنترنت لإنشاء قائمة جديدة');
    }

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
    final currentLists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
    final updatedLists = List<ShoppingListModel>.from(currentLists);
    if (!updatedLists.any((l) => l.id == effectiveId)) {
      updatedLists.add(newList);
    }
    await _localDataSource.saveShoppingListsStreamCache(homeId: homeId, lists: updatedLists);
    LocalCacheNotifier.notify(homeId, 'shopping_lists');

    // 2. Perform online operation
    try {
      final serverList = await _remoteRepository.createShoppingList(
        homeId: homeId,
        name: name,
        description: description,
        icon: icon,
      );
      // Replace temp model with actual server model to ensure timestamps are synced
      final refreshedLists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      final finalLists = refreshedLists.map((l) => l.id == effectiveId ? serverList : l).toList();
      await _localDataSource.saveShoppingListsStreamCache(homeId: homeId, lists: finalLists);
      return serverList;
    } catch (_) {
      // Revert if failed
      final refreshedLists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      final finalLists = refreshedLists.where((l) => l.id != effectiveId).toList();
      await _localDataSource.saveShoppingListsStreamCache(homeId: homeId, lists: finalLists);
      LocalCacheNotifier.notify(homeId, 'shopping_lists');
      rethrow;
    }
  }

  @override
  Future<ShoppingListModel> updateShoppingList({
    required String listId,
    String? name,
    String? description,
    String? status,
  }) async {
    if (!(await _isOnline)) {
      throw Exception('يجب توفر اتصال بالإنترنت لتعديل القائمة');
    }

    ShoppingListModel? originalList;
    
    // 1. Always optimistically update the local cache first!
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final currentLists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      final index = currentLists.indexWhere((l) => l.id == listId);
      if (index != -1) {
        originalList = currentLists[index];
        final updated = ShoppingListModel(
          id: originalList.id,
          homeId: originalList.homeId,
          name: name ?? originalList.name,
          description: description ?? originalList.description,
          icon: originalList.icon,
          status: status != null
              ? (status == 'active' ? ShoppingListStatus.active : ShoppingListStatus.archived)
              : originalList.status,
          createdBy: originalList.createdBy,
          createdAt: originalList.createdAt,
          updatedAt: DateTime.now(),
        );
        
        final updatedLists = List<ShoppingListModel>.from(currentLists);
        updatedLists[index] = updated;
        await _localDataSource.saveShoppingListsStreamCache(homeId: homeId, lists: updatedLists);
        LocalCacheNotifier.notify(homeId, 'shopping_lists');
      }
    }

    // 2. Perform online operation
    try {
      final serverList = await _remoteRepository.updateShoppingList(
        listId: listId,
        name: name,
        description: description,
        status: status,
      );
      if (homeId != null && homeId.isNotEmpty) {
        final current = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
        final updated = current.map((l) => l.id == listId ? serverList : l).toList();
        await _localDataSource.saveShoppingListsStreamCache(homeId: homeId, lists: updated);
      }
      return serverList;
    } catch (_) {
      // Revert if failed
      if (homeId != null && homeId.isNotEmpty && originalList != null) {
        final current = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
        final reverted = current.map((l) => l.id == listId ? originalList! : l).toList();
        await _localDataSource.saveShoppingListsStreamCache(homeId: homeId, lists: reverted);
        LocalCacheNotifier.notify(homeId, 'shopping_lists');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteShoppingList({required String listId}) async {
    // 1. Optimistically update local cache and notify UI instantly
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final current = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      final updated = current.where((l) => l.id != listId).toList();
      await _localDataSource.saveShoppingListsStreamCache(
        homeId: homeId,
        lists: updated,
      );
      LocalCacheNotifier.notify(homeId, 'shopping_lists');
    }

    // 2. Perform remote deletion if online
    try {
      if (await _isOnline) {
        await _remoteRepository.deleteShoppingList(listId: listId);
      }
    } catch (_) {
      // Swallowed - offline or failed, but since we are optimistic, it remains removed locally
    }
  }

  @override
  Stream<List<ShoppingListModel>> watchShoppingLists({required String homeId}) async* {
    // 1. Emit cached lists instantly (0 network requests, instant perceived loading)
    yield await _localDataSource.getShoppingListsStreamCache(homeId: homeId);

    // 2. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'shopping_lists') {
        yield await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      }
    }
  }

  // Shopping Items
  @override
  Future<List<ShoppingItemModel>> getShoppingItems({required String listId}) async {
    // Return cached items instantly (100% Local-First Single Source of Truth)
    // No remote fetching is triggered from getters. Initial sync is handled solely by SyncCoordinator.
    return _localDataSource.getShoppingItemsStreamCache(listId: listId);
  }

  @override
  Future<ShoppingItemModel?> getShoppingItemById({required String itemId}) async {
    final homeId = _homeId;
    if (homeId != null) {
      final lists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      for (final list in lists) {
        final items = await _localDataSource.getShoppingItemsStreamCache(listId: list.id);
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
      currency: currency ?? 'TRY',
      notes: notes,
      createdBy: userId,
    );

    // 1. Always optimistically update the local cache first!
    final currentItems = await _localDataSource.getShoppingItemsStreamCache(listId: listId);
    final updatedItems = List<ShoppingItemModel>.from(currentItems);
    if (!updatedItems.any((i) => i.id == effectiveId)) {
      updatedItems.add(newItem);
    }
    await _localDataSource.saveShoppingItemsStreamCache(listId: listId, items: updatedItems);
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      LocalCacheNotifier.notify(homeId, 'shopping_items');
    }

    // 2. Perform online/offline operation
    if (await _isOnline) {
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
        final refreshedItems = await _localDataSource.getShoppingItemsStreamCache(listId: listId);
        final finalItems = refreshedItems.map((i) => i.id == effectiveId ? serverItem : i).toList();
        await _localDataSource.saveShoppingItemsStreamCache(listId: listId, items: finalItems);
        return serverItem;
      } catch (_) {
        // Enqueue
        await _queueRepository.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: effectiveId,
          homeId: _homeId ?? listId,
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
        homeId: _homeId ?? listId,
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
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  }) async {
    // 1. Find and optimistically update the local cache
    String targetListId = '';
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final lists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      for (final list in lists) {
        final currentItems = await _localDataSource.getShoppingItemsStreamCache(listId: list.id);
        final index = currentItems.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          targetListId = list.id;
          final original = currentItems[index];
          final updated = ShoppingItemModel(
            id: original.id,
            shoppingListId: original.shoppingListId,
            name: name ?? original.name,
            quantity: quantity ?? original.quantity,
            purchasedQuantity: purchasedQuantity ?? original.purchasedQuantity,
            unitId: unitId ?? original.unitId,
            categoryId: categoryId ?? original.categoryId,
            price: price ?? original.price,
            currency: original.currency,
            notes: notes ?? original.notes,
            isPurchased: original.isPurchased,
            createdBy: original.createdBy,
            createdAt: original.createdAt,
            updatedAt: DateTime.now(),
          );
          
          final updatedItems = List<ShoppingItemModel>.from(currentItems);
          updatedItems[index] = updated;
          await _localDataSource.saveShoppingItemsStreamCache(listId: list.id, items: updatedItems);
          LocalCacheNotifier.notify(homeId, 'shopping_items');
          break;
        }
      }
    }

    final payload = {
      'name': name,
      'quantity': quantity,
      'purchased_quantity': purchasedQuantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'price': price,
      'note': notes,
    }..removeWhere((_, v) => v == null);

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
          final current = await _localDataSource.getShoppingItemsStreamCache(listId: targetListId);
          final updated = current.map((i) => i.id == itemId ? serverItem : i).toList();
          await _localDataSource.saveShoppingItemsStreamCache(listId: targetListId, items: updated);
        }
        return serverItem;
      } catch (_) {
        await _queueRepository.enqueueAction(
          actionType: ActionType.updateItem,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: _homeId ?? '',
          payload: payload,
        );
      }
    } else {
      await _queueRepository.enqueueAction(
        actionType: ActionType.updateItem,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: _homeId ?? '',
        payload: payload,
      );
    }

    final userId = await _getUserId();
    return ShoppingItemModel(
      id: itemId,
      shoppingListId: targetListId,
      name: name ?? '',
      quantity: quantity ?? 1,
      purchasedQuantity: purchasedQuantity ?? 0,
      unitId: unitId,
      categoryId: categoryId,
      price: price,
      notes: notes,
      createdBy: userId,
    );
  }

  @override
  Future<void> deleteShoppingItem({required String itemId}) async {
    // 1. Optimistically update local cache and notify UI instantly
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final lists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      for (final list in lists) {
        final currentItems = await _localDataSource.getShoppingItemsStreamCache(listId: list.id);
        final hasItem = currentItems.any((i) => i.id == itemId);
        if (hasItem) {
          final updatedItems = currentItems.where((i) => i.id != itemId).toList();
          await _localDataSource.saveShoppingItemsStreamCache(
            listId: list.id,
            items: updatedItems,
          );
          LocalCacheNotifier.notify(homeId, 'shopping_items');
          break;
        }
      }
    }

    // 2. Perform background/remote deletion
    try {
      if (await _isOnline) {
        await _remoteRepository.deleteShoppingItem(itemId: itemId);
      } else {
        await _queueRepository.enqueueAction(
          actionType: ActionType.deleteItem,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: _homeId ?? '',
          payload: {},
        );
      }
    } catch (_) {
      // Fallback to offline queue if remote call fails
      await _queueRepository.enqueueAction(
        actionType: ActionType.deleteItem,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: _homeId ?? '',
        payload: {},
      );
    }
  }

  @override
  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  }) async {
    // 1. Optimistically update the local cache
    String targetListId = '';
    final homeId = _homeId;
    if (homeId != null && homeId.isNotEmpty) {
      final lists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
      for (final list in lists) {
        final currentItems = await _localDataSource.getShoppingItemsStreamCache(listId: list.id);
        final index = currentItems.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          targetListId = list.id;
          final original = currentItems[index];
          final updated = ShoppingItemModel(
            id: original.id,
            shoppingListId: original.shoppingListId,
            name: original.name,
            quantity: original.quantity,
            unitId: original.unitId,
            categoryId: original.categoryId,
            price: original.price,
            currency: original.currency,
            notes: original.notes,
            isPurchased: isPurchased,
            createdBy: original.createdBy,
            createdAt: original.createdAt,
            updatedAt: DateTime.now(),
          );
          
          final updatedItems = List<ShoppingItemModel>.from(currentItems);
          updatedItems[index] = updated;
          await _localDataSource.saveShoppingItemsStreamCache(listId: list.id, items: updatedItems);
          LocalCacheNotifier.notify(homeId, 'shopping_items');
          break;
        }
      }
    }

    final payload = {
      'status': isPurchased ? 'completed' : 'pending',
      'completed_at': isPurchased ? DateTime.now().toIso8601String() : null,
    };

    // 2. Perform online/offline operation
    if (await _isOnline) {
      try {
        final serverItem = await _remoteRepository.markItemPurchased(
          itemId: itemId,
          isPurchased: isPurchased,
        );
        if (targetListId.isNotEmpty) {
          final current = await _localDataSource.getShoppingItemsStreamCache(listId: targetListId);
          final updated = current.map((i) => i.id == itemId ? serverItem : i).toList();
          await _localDataSource.saveShoppingItemsStreamCache(listId: targetListId, items: updated);
        }
        return serverItem;
      } catch (_) {
        await _queueRepository.enqueueAction(
          actionType: ActionType.markPurchased,
          entityType: EntityType.shoppingItem,
          entityId: itemId,
          homeId: _homeId ?? '',
          payload: payload,
        );
      }
    } else {
      await _queueRepository.enqueueAction(
        actionType: ActionType.markPurchased,
        entityType: EntityType.shoppingItem,
        entityId: itemId,
        homeId: _homeId ?? '',
        payload: payload,
      );
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
  Future<List<ShoppingItemModel>> getPurchaseHistory({
    required String homeId,
    int limit = 50,
  }) {
    return _remoteRepository.getPurchaseHistory(homeId: homeId, limit: limit);
  }

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItems({required String listId}) async* {
    // 1. Emit cached items instantly (0 network requests, instant perceived loading)
    yield await _localDataSource.getShoppingItemsStreamCache(listId: listId);

    // 2. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == _homeId && event.entityType == 'shopping_items') {
        yield await _localDataSource.getShoppingItemsStreamCache(listId: listId);
      }
    }
  }

  // Item Templates
  @override
  Future<List<ItemTemplateModel>> getItemTemplates({required String homeId}) async {
    final cached = await _localDataSource.getItemTemplates(homeId: homeId);
    if (cached.isNotEmpty) return cached;

    try {
      final templates = await _remoteRepository.getItemTemplates(homeId: homeId);
      await _localDataSource.saveItemTemplates(homeId: homeId, templates: templates);
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
  Stream<List<ItemTemplateModel>> watchItemTemplates({required String homeId}) async* {
    // 1. Emit cached templates instantly
    yield await _localDataSource.getItemTemplates(homeId: homeId);

    // 2. React to local cache updates
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
  }) {
    return _remoteRepository.getAutocompleteSuggestions(
      homeId: homeId,
      query: query,
      limit: limit,
    );
  }

  @override
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
  }) {
    return _remoteRepository.syncTemplateOnAdd(
      homeId: homeId,
      name: name,
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
    );
  }

  @override
  Future<void> syncShoppingWithServer(String homeId) async {
    try {
      final serverUpdates = await _syncService.getServerLastUpdates(homeId);

      // 1. Sync Shopping Lists if server is newer or local cache is empty
      final serverListsMaxUpdate = serverUpdates['shopping_lists'];
      if (serverListsMaxUpdate != null) {
        final localSyncTime = _syncService.getLocalSyncTime(homeId, 'shopping_lists');
        final cachedLists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
        final isCacheEmpty = cachedLists.isEmpty;

        if (isCacheEmpty || serverListsMaxUpdate.isAfter(localSyncTime)) {
          final lists = await _remoteRepository.getShoppingLists(homeId: homeId);

          // Save to local cache
          await _localDataSource.saveShoppingListsStreamCache(
            homeId: homeId,
            status: null,
            lists: lists,
          );

          // Update local sync time
          DateTime maxTs = DateTime.fromMillisecondsSinceEpoch(0);
          for (final l in lists) {
            if (l.updatedAt != null && l.updatedAt!.isAfter(maxTs)) {
              maxTs = l.updatedAt!;
            }
            if (l.createdAt != null && l.createdAt!.isAfter(maxTs)) {
              maxTs = l.createdAt!;
            }
          }
          if (maxTs.year > 1970) {
            await _syncService.updateLocalSyncTime(homeId, 'shopping_lists', maxTs);
          } else {
            await _syncService.updateLocalSyncTime(homeId, 'shopping_lists', DateTime.now());
          }

          // Notify reactive list stream
          LocalCacheNotifier.notify(homeId, 'shopping_lists');
        }
      }

      // 2. Sync Shopping Items if server is newer or local cache is empty
      final serverItemsMaxUpdate = serverUpdates['shopping_items'];
      if (serverItemsMaxUpdate != null) {
        final localSyncTime = _syncService.getLocalSyncTime(homeId, 'shopping_items');
        final lists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);
        
        bool isCacheEmpty = true;
        for (final list in lists) {
          final cachedItems = await _localDataSource.getShoppingItemsStreamCache(listId: list.id);
          if (cachedItems.isNotEmpty) {
            isCacheEmpty = false;
            break;
          }
        }

        if (isCacheEmpty || serverItemsMaxUpdate.isAfter(localSyncTime)) {
          // Load all active lists in the home
          final lists = await _localDataSource.getShoppingListsStreamCache(homeId: homeId);

          // Fetch items for all lists in parallel and cache them
          await Future.wait(
            lists.map((list) async {
              try {
                final items = await _remoteRepository.getShoppingItems(listId: list.id);
                await _localDataSource.saveShoppingItemsStreamCache(
                  listId: list.id,
                  items: items,
                );
              } catch (_) {}
            }),
          );

          // Update local sync time
          await _syncService.updateLocalSyncTime(homeId, 'shopping_items', serverItemsMaxUpdate);

          // Notify reactive items stream
          LocalCacheNotifier.notify(homeId, 'shopping_items');
        }
      }

      // 3. Sync Item Templates
      try {
        final templates = await _remoteRepository.getItemTemplates(homeId: homeId);
        await _localDataSource.saveItemTemplates(homeId: homeId, templates: templates);
        LocalCacheNotifier.notify(homeId, 'item_templates');
      } catch (_) {}

    } catch (_) {
      rethrow;
    }
  }
}
