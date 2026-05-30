import 'dart:convert';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/category_model.dart';

/// Abstract interface for local persistence of Categories.
/// Supports future migration to Drift/SQLite, Hive, or Isar.
abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories({
    String? homeId,
    String? type,
  });

  Future<void> saveCategories({
    String? homeId,
    String? type,
    required List<CategoryModel> categories,
  });
}

/// SharedPreferences-based implementation of [CategoryLocalDataSource].
class SharedPreferencesCategoryLocalDataSource implements CategoryLocalDataSource {
  String _getCacheKey(String? homeId, String? type) =>
      'cached_categories_${homeId ?? "none"}_${type ?? "none"}';

  @override
  Future<List<CategoryModel>> getCategories({
    String? homeId,
    String? type,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getCacheKey(homeId, type);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCategories({
    String? homeId,
    String? type,
    required List<CategoryModel> categories,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getCacheKey(homeId, type);
      final jsonStr = jsonEncode(categories.map((c) => c.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }
}
