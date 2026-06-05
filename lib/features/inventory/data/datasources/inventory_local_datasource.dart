import 'dart:convert';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/inventory_item_model.dart';

/// Abstract interface for local persistence of Inventory Items.
/// Prepares SAWA for SQLite/Drift/Isar migrations.
abstract class InventoryLocalDataSource {
  Future<List<InventoryItemModel>> getInventoryItems({
    required String homeId,
  });

  Future<void> saveInventoryItems({
    required String homeId,
    required List<InventoryItemModel> items,
  });

  Future<List<InventoryItemModel>> getInventoryItemsStreamCache({
    required String homeId,
  });

  Future<void> saveInventoryItemsStreamCache({
    required String homeId,
    required List<InventoryItemModel> items,
  });
}

/// SharedPreferences-based implementation of [InventoryLocalDataSource].
class SharedPreferencesInventoryLocalDataSource implements InventoryLocalDataSource {
  String _getInventoryKey(String homeId) =>
      'cached_inventory_$homeId';

  String _getStreamKey(String homeId) =>
      'cached_inventory_stream_$homeId';

  @override
  Future<List<InventoryItemModel>> getInventoryItems({
    required String homeId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getInventoryKey(homeId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => InventoryItemModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveInventoryItems({
    required String homeId,
    required List<InventoryItemModel> items,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getInventoryKey(homeId);
      final jsonStr = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<InventoryItemModel>> getInventoryItemsStreamCache({
    required String homeId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getStreamKey(homeId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => InventoryItemModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveInventoryItemsStreamCache({
    required String homeId,
    required List<InventoryItemModel> items,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getStreamKey(homeId);
      final jsonStr = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }
}
