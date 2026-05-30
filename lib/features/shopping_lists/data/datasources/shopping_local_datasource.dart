import 'dart:convert';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../models/item_template_model.dart';

/// Abstract interface for local persistence of Shopping Lists and Items.
/// Prepares Beity for SQLite/Drift/Isar migrations.
abstract class ShoppingLocalDataSource {
  Future<List<ShoppingListModel>> getShoppingListsStreamCache({
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

  Future<void> saveShoppingItemsStreamCache({
    required String listId,
    required List<ShoppingItemModel> items,
  });

  Future<List<ItemTemplateModel>> getItemTemplates({
    required String homeId,
  });

  Future<void> saveItemTemplates({
    required String homeId,
    required List<ItemTemplateModel> templates,
  });

  Future<String> getLastLoggedInUserId();
}

/// SharedPreferences-based implementation of [ShoppingLocalDataSource].
class SharedPreferencesShoppingLocalDataSource implements ShoppingLocalDataSource {
  String _getListsKey(String homeId, String? status) =>
      'cached_lists_stream_${homeId}_${status ?? "all"}';

  String _getItemsKey(String listId) =>
      'cached_items_stream_$listId';

  String _getTemplatesKey(String homeId) =>
      'cached_templates_$homeId';

  @override
  Future<List<ShoppingListModel>> getShoppingListsStreamCache({
    required String homeId,
    String? status,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getListsKey(homeId, status);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => ShoppingListModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveShoppingListsStreamCache({
    required String homeId,
    String? status,
    required List<ShoppingListModel> lists,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getListsKey(homeId, status);
      final jsonStr = jsonEncode(lists.map((l) => l.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<ShoppingItemModel>> getShoppingItemsStreamCache({
    required String listId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getItemsKey(listId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => ShoppingItemModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveShoppingItemsStreamCache({
    required String listId,
    required List<ShoppingItemModel> items,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getItemsKey(listId);
      final jsonStr = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<ItemTemplateModel>> getItemTemplates({
    required String homeId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getTemplatesKey(homeId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => ItemTemplateModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveItemTemplates({
    required String homeId,
    required List<ItemTemplateModel> templates,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getTemplatesKey(homeId);
      final jsonStr = jsonEncode(templates.map((t) => t.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
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
