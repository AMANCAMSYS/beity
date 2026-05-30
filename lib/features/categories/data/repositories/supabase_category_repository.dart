import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';
import 'category_repository.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client;
  final CategoryLocalDataSource _localDataSource;
  final SyncService _syncService;

  SupabaseCategoryRepository(
    this._client,
    this._localDataSource,
    this._syncService,
  );

  @override
  Future<List<CategoryModel>> getCategories({
    String? homeId,
    String? type,
  }) async {
    // 1. Load from local datasource (instant perceived loading)
    final cached = await _localDataSource.getCategories(
      homeId: homeId,
      type: type,
    );
    if (cached.isNotEmpty) {
      return cached;
    }

    // 2. Fallback to remote query only if cache is completely empty (first run)
    try {
      var query = _client
          .from('categories')
          .select()
          .isFilter('deleted_at', null);

      if (homeId != null && homeId.isNotEmpty) {
        query = query.or('is_default.eq.true,home_id.eq.$homeId');
      } else {
        query = query.eq('is_default', true);
      }

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('sort_order', ascending: true);
      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      // Save to local cache
      await _localDataSource.saveCategories(
        homeId: homeId,
        type: type,
        categories: categories,
      );

      return categories;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<CategoryModel> createCategory({
    required String homeId,
    required String name,
    required String type,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check for duplicate name
    final existing = await _client
        .from('categories')
        .select('id')
        .eq('home_id', homeId)
        .eq('name', name)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (existing != null) {
      throw Exception('اسم التصنيف موجود بالفعل');
    }

    final response = await _client
        .from('categories')
        .insert({
          'home_id': homeId,
          'name': name,
          'type': type,
          'icon': icon,
          'color': color,
          'sort_order': sortOrder ?? 0,
          'is_default': false,
          'created_by': user.id,
        })
        .select()
        .single();

    final newCategory = CategoryModel.fromJson(response);

    // Optimistically update local cache & notify
    final current = await _localDataSource.getCategories(homeId: homeId, type: type);
    final updated = [...current, newCategory]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _localDataSource.saveCategories(homeId: homeId, type: type, categories: updated);
    LocalCacheNotifier.notify(homeId, 'categories');

    return newCategory;
  }

  @override
  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if category is default
    final category = await _client
        .from('categories')
        .select('is_default, home_id')
        .eq('id', categoryId)
        .single();

    if (category['is_default'] == true) {
      throw Exception('لا يمكن تعديل التصنيفات الافتراضية');
    }

    final homeId = category['home_id'] as String;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    final response = await _client
        .from('categories')
        .update(updates)
        .eq('id', categoryId)
        .select()
        .single();

    final updatedCategory = CategoryModel.fromJson(response);

    // Update local cache & notify
    final current = await _localDataSource.getCategories(homeId: homeId);
    final updated = current.map((c) => c.id == categoryId ? updatedCategory : c).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _localDataSource.saveCategories(homeId: homeId, categories: updated);
    LocalCacheNotifier.notify(homeId, 'categories');

    return updatedCategory;
  }

  @override
  Future<void> deleteCategory({
    required String categoryId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if category is default
    final category = await _client
        .from('categories')
        .select('is_default, home_id')
        .eq('id', categoryId)
        .single();

    if (category['is_default'] == true) {
      throw Exception('لا يمكن حذف التصنيفات الافتراضية');
    }

    final homeId = category['home_id'] as String;

    await _client
        .from('categories')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', categoryId);

    // Update local cache & notify
    final current = await _localDataSource.getCategories(homeId: homeId);
    final updated = current.where((c) => c.id != categoryId).toList();
    await _localDataSource.saveCategories(homeId: homeId, categories: updated);
    LocalCacheNotifier.notify(homeId, 'categories');
  }

  @override
  Future<CategoryModel?> getCategoryById({
    required String categoryId,
  }) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('id', categoryId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    return CategoryModel.fromJson(response);
  }

  @override
  Stream<List<CategoryModel>> watchCategories({
    String? homeId,
    String? type,
  }) async* {
    Future<List<CategoryModel>> loadCache() async {
      return _localDataSource.getCategories(
        homeId: homeId,
        type: type,
      );
    }

    // 1. Emit cached categories instantly (0 network requests, instant perceived loading)
    yield await loadCache();

    // 2. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if ((homeId == null || event.homeId == homeId) && event.entityType == 'categories') {
        yield await loadCache();
      }
    }
  }

  @override
  Future<void> syncCategoriesWithServer(String homeId) async {
    try {
      final serverUpdates = await _syncService.getServerLastUpdates(homeId);
      final serverCategoriesMaxUpdate = serverUpdates['categories'];

      if (serverCategoriesMaxUpdate != null) {
        final localSyncTime = _syncService.getLocalSyncTime(homeId, 'categories');
        final cachedCategories = await _localDataSource.getCategories(homeId: homeId);
        final isCacheEmpty = cachedCategories.isEmpty;

        // Delta Sync check: Only pull if the server has newer updates OR local cache is empty!
        if (isCacheEmpty || serverCategoriesMaxUpdate.isAfter(localSyncTime)) {
          final response = await _client
              .from('categories')
              .select()
              .isFilter('deleted_at', null)
              .or('is_default.eq.true,home_id.eq.$homeId')
              .order('sort_order', ascending: true);

          final categories = (response as List)
              .map((json) => CategoryModel.fromJson(json))
              .toList();

          // Save to local cache
          await _localDataSource.saveCategories(
            homeId: homeId,
            categories: categories,
          );

          // Update local sync time
          DateTime maxTs = DateTime.fromMillisecondsSinceEpoch(0);
          for (final c in categories) {
            if (c.updatedAt != null && c.updatedAt!.isAfter(maxTs)) {
              maxTs = c.updatedAt!;
            }
            if (c.createdAt != null && c.createdAt!.isAfter(maxTs)) {
              maxTs = c.createdAt!;
            }
          }
          if (maxTs.year > 1970) {
            await _syncService.updateLocalSyncTime(homeId, 'categories', maxTs);
          } else {
            await _syncService.updateLocalSyncTime(homeId, 'categories', DateTime.now());
          }

          // Notify reactive streams
          LocalCacheNotifier.notify(homeId, 'categories');
        }
      }
    } catch (_) {
      rethrow;
    }
  }
}
