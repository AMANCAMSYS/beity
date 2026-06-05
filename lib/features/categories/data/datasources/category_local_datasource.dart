import 'dart:convert';
import 'package:sawa/core/local_database/daos/categories_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/category_model.dart';

/// Abstract interface for local persistence of Categories.
/// Supports future migration to Drift/SQLite, Hive, or Isar.
abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories({String? homeId, String? type});

  Future<CategoryModel?> getCategoryById(String categoryId);

  Future<void> saveCategories({
    String? homeId,
    String? type,
    required List<CategoryModel> categories,
  });
}

/// SharedPreferences-based implementation of [CategoryLocalDataSource].
class SharedPreferencesCategoryLocalDataSource
    implements CategoryLocalDataSource {
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
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    final categories = await getCategories();
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
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

class DriftCategoryLocalDataSource implements CategoryLocalDataSource {
  DriftCategoryLocalDataSource({CategoriesDao? dao})
    : _dao = dao ?? CategoriesDao(LocalDatabaseService.instance);

  final CategoriesDao _dao;

  @override
  Future<List<CategoryModel>> getCategories({String? homeId, String? type}) {
    return _dao.getCategories(homeId: homeId, type: type);
  }

  @override
  Future<CategoryModel?> getCategoryById(String categoryId) {
    return _dao.getCategoryById(categoryId);
  }

  @override
  Future<void> saveCategories({
    String? homeId,
    String? type,
    required List<CategoryModel> categories,
  }) {
    return _dao.upsertCategories(categories);
  }

  Future<void> softDeleteCategory({
    required String categoryId,
    DateTime? deletedAt,
  }) {
    return _dao.softDeleteCategory(categoryId, deletedAt ?? DateTime.now());
  }
}
