import 'dart:convert';
import 'dart:isolate';
import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/daos/shopping_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/services/local_cache_notifier.dart';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../models/item_template_model.dart';
import '../../../../core/monitoring/monitoring_service.dart';

/// Abstract interface for local persistence of Shopping Lists and Items.
/// Prepares SAWA for SQLite/Drift/Isar migrations.
abstract class ShoppingLocalDataSource {
  Future<List<ShoppingListModel>> getShoppingListsStreamCache({
    required String homeId,
    String? status,
  });

  Stream<List<ShoppingListModel>> watchShoppingListsStreamCache({
    required String homeId,
    String? status,
  });

  Future<void> saveShoppingListsStreamCache({
    required String homeId,
    String? status,
    required List<ShoppingListModel> lists,
  });

  Future<List<ShoppingItemModel>> getShoppingItemsStreamCache({
    required String listId,
  });

  Stream<List<ShoppingItemModel>> watchShoppingItemsStreamCache({
    required String listId,
  });

  Future<void> saveShoppingItemsStreamCache({
    required String listId,
    required List<ShoppingItemModel> items,
  });

  Future<List<ItemTemplateModel>> getItemTemplates({required String homeId});

  Future<void> saveItemTemplates({
    required String homeId,
    required List<ItemTemplateModel> templates,
  });

  Future<String> getLastLoggedInUserId();
}

/// SharedPreferences-based implementation of [ShoppingLocalDataSource].
class SharedPreferencesShoppingLocalDataSource
    implements ShoppingLocalDataSource {
  // In-memory caches for O(1) access
  final Map<String, List<ShoppingListModel>> _listsMemoryCache = {};
  final Map<String, List<ShoppingItemModel>> _itemsMemoryCache = {};
  final Map<String, List<ItemTemplateModel>> _templatesMemoryCache = {};

  String _getListsKey(String homeId, String? status) =>
      'cached_lists_stream_${homeId}_${status ?? "all"}';

  String _getItemsKey(String listId) => 'cached_items_stream_$listId';

  String _getTemplatesKey(String homeId) => 'cached_templates_$homeId';

  @override
  Future<List<ShoppingListModel>> getShoppingListsStreamCache({
    required String homeId,
    String? status,
  }) async {
    final key = _getListsKey(homeId, status);
    if (_listsMemoryCache.containsKey(key)) {
      return _listsMemoryCache[key]!;
    }
    try {
      final prefs = AppPreferences.instance;
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      final models = list
          .map((json) => ShoppingListModel.fromJson(json))
          .toList();
      _listsMemoryCache[key] = models;
      return models;
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<ShoppingListModel>> watchShoppingListsStreamCache({
    required String homeId,
    String? status,
  }) async* {
    yield await getShoppingListsStreamCache(homeId: homeId, status: status);
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'shopping_lists') {
        yield await getShoppingListsStreamCache(homeId: homeId, status: status);
      }
    }
  }

  @override
  Future<void> saveShoppingListsStreamCache({
    required String homeId,
    String? status,
    required List<ShoppingListModel> lists,
  }) async {
    final key = _getListsKey(homeId, status);
    // Update memory cache instantly (O(1) for UI)
    _listsMemoryCache[key] = List.from(lists);

    try {
      final prefs = AppPreferences.instance;
      // Offload heavy JSON serialization to background thread
      final jsonStr = await Isolate.run(
        () => jsonEncode(lists.map((l) => l.toJson()).toList()),
      );
      await prefs.setString(key, jsonStr);
    } catch (e, s) {
      MonitoringService().logError(
        e,
        s,
        reason: 'Shopping lists cache save failed for $homeId',
      );
    }
  }

  @override
  Future<List<ShoppingItemModel>> getShoppingItemsStreamCache({
    required String listId,
  }) async {
    final key = _getItemsKey(listId);
    if (_itemsMemoryCache.containsKey(key)) {
      return _itemsMemoryCache[key]!;
    }
    try {
      final prefs = AppPreferences.instance;
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      final models = list
          .map((json) => ShoppingItemModel.fromJson(json))
          .toList();
      _itemsMemoryCache[key] = models;
      return models;
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItemsStreamCache({
    required String listId,
  }) async* {
    yield await getShoppingItemsStreamCache(listId: listId);
    await for (final event in LocalCacheNotifier.stream) {
      if (event.entityType == 'shopping_items' &&
          (event.listId == null || event.listId == listId)) {
        yield await getShoppingItemsStreamCache(listId: listId);
      }
    }
  }

  @override
  Future<void> saveShoppingItemsStreamCache({
    required String listId,
    required List<ShoppingItemModel> items,
  }) async {
    final key = _getItemsKey(listId);
    // Update memory cache instantly (O(1) for UI)
    _itemsMemoryCache[key] = List.from(items);

    try {
      final prefs = AppPreferences.instance;
      // Offload heavy JSON serialization to background thread
      final jsonStr = await Isolate.run(
        () => jsonEncode(items.map((i) => i.toJson()).toList()),
      );
      await prefs.setString(key, jsonStr);
    } catch (e, s) {
      MonitoringService().logError(
        e,
        s,
        reason: 'Shopping items cache save failed for $listId',
      );
    }
  }

  @override
  Future<List<ItemTemplateModel>> getItemTemplates({
    required String homeId,
  }) async {
    final key = _getTemplatesKey(homeId);
    if (_templatesMemoryCache.containsKey(key)) {
      return _templatesMemoryCache[key]!;
    }
    try {
      final prefs = AppPreferences.instance;
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      final models = list
          .map((json) => ItemTemplateModel.fromJson(json))
          .toList();
      _templatesMemoryCache[key] = models;
      return models;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveItemTemplates({
    required String homeId,
    required List<ItemTemplateModel> templates,
  }) async {
    final key = _getTemplatesKey(homeId);
    // Update memory cache instantly (O(1) for UI)
    _templatesMemoryCache[key] = List.from(templates);

    try {
      final prefs = AppPreferences.instance;
      // Offload heavy JSON serialization to background thread
      final jsonStr = await Isolate.run(
        () => jsonEncode(templates.map((t) => t.toJson()).toList()),
      );
      await prefs.setString(key, jsonStr);
    } catch (e, s) {
      MonitoringService().logError(
        e,
        s,
        reason: 'Item templates cache save failed for $homeId',
      );
    }
  }

  @override
  Future<String> getLastLoggedInUserId() async {
    try {
      final prefs = AppPreferences.instance;
      return prefs.getString('last_logged_in_user_id') ?? 'anonymous';
    } catch (_) {
      return 'anonymous';
    }
  }
}

/// Drift/SQLite implementation of [ShoppingLocalDataSource].
///
/// This is the permanent local-first store used for shopping MVP data. The
/// SharedPreferences implementation remains in the file only as a rollback and
/// migration source while the app transitions existing installs.
class DriftShoppingLocalDataSource implements ShoppingLocalDataSource {
  DriftShoppingLocalDataSource({ShoppingDao? dao})
    : _dao = dao ?? ShoppingDao(LocalDatabaseService.instance);

  final ShoppingDao _dao;

  @override
  Future<List<ShoppingListModel>> getShoppingListsStreamCache({
    required String homeId,
    String? status,
  }) {
    return _dao.getShoppingLists(homeId: homeId, status: status);
  }

  @override
  Stream<List<ShoppingListModel>> watchShoppingListsStreamCache({
    required String homeId,
    String? status,
  }) {
    return _dao.watchShoppingLists(homeId: homeId, status: status);
  }

  @override
  Future<void> saveShoppingListsStreamCache({
    required String homeId,
    String? status,
    required List<ShoppingListModel> lists,
  }) {
    return _dao.upsertShoppingLists(lists);
  }

  Future<void> saveShoppingListsWithLocalState({
    required String homeId,
    required List<ShoppingListModel> lists,
    required String localState,
    String? syncError,
  }) {
    return _dao.upsertShoppingListsWithLocalState(
      lists: lists,
      localState: localState,
      syncError: syncError,
    );
  }

  Future<void> softDeleteShoppingList({
    required String listId,
    DateTime? deletedAt,
    String localState = localStateSynced,
  }) {
    return _dao.softDeleteShoppingList(
      listId,
      deletedAt ?? DateTime.now(),
      localState: localState,
    );
  }

  @override
  Future<List<ShoppingItemModel>> getShoppingItemsStreamCache({
    required String listId,
  }) {
    return _dao.getShoppingItems(listId);
  }

  Stream<ShoppingListModel?> watchShoppingListById(String listId) {
    return _dao.watchShoppingListById(listId);
  }

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItemsStreamCache({
    required String listId,
  }) {
    return _dao.watchShoppingItems(listId);
  }

  @override
  Future<void> saveShoppingItemsStreamCache({
    required String listId,
    required List<ShoppingItemModel> items,
  }) {
    return _dao.upsertShoppingItems(listId: listId, items: items);
  }

  Future<void> saveShoppingItemsWithLocalState({
    required String listId,
    required List<ShoppingItemModel> items,
    required String localState,
    String? syncError,
    String? homeId,
  }) {
    return _dao.upsertShoppingItemsWithLocalState(
      listId: listId,
      items: items,
      localState: localState,
      syncError: syncError,
      homeId: homeId,
    );
  }

  Future<void> softDeleteShoppingItem({
    required String itemId,
    DateTime? deletedAt,
    String localState = localStateSynced,
  }) {
    return _dao.softDeleteShoppingItem(
      itemId,
      deletedAt ?? DateTime.now(),
      localState: localState,
    );
  }

  @override
  Future<List<ItemTemplateModel>> getItemTemplates({required String homeId}) {
    return _dao.getItemTemplates(homeId);
  }

  @override
  Future<void> saveItemTemplates({
    required String homeId,
    required List<ItemTemplateModel> templates,
  }) {
    return _dao.upsertItemTemplates(templates);
  }

  @override
  Future<String> getLastLoggedInUserId() async {
    try {
      final prefs = AppPreferences.instance;
      return prefs.getString('last_logged_in_user_id') ?? 'anonymous';
    } catch (_) {
      return 'anonymous';
    }
  }
}
