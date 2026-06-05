import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../../../offline_queue/data/datasources/drift_queue_datasource.dart';
import '../../../offline_queue/domain/entities/action_type.dart';
import '../../../offline_queue/domain/entities/entity_type.dart';
import '../../domain/entities/category.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';
import 'category_repository.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  static const int _pageSize = 500;

  final SupabaseClient _client;
  final CategoryLocalDataSource _localDataSource;
  final SyncService _syncService;
  final DriftQueueDataSource _queueDataSource;

  SupabaseCategoryRepository(
    this._client,
    this._localDataSource,
    this._syncService, [
    DriftQueueDataSource? queueDataSource,
  ]) : _queueDataSource = queueDataSource ?? DriftQueueDataSource();

  Future<List<CategoryModel>> _fetchCategoriesPageable({
    String? homeId,
    String? type,
    bool includeDeleted = false,
  }) async {
    final categories = <CategoryModel>[];

    for (var offset = 0; ; offset += _pageSize) {
      var query = _client.from('categories').select();

      if (!includeDeleted) {
        query = query.isFilter('deleted_at', null);
      }

      if (homeId != null && homeId.isNotEmpty) {
        query = query.or('is_default.eq.true,home_id.eq.$homeId');
      } else {
        query = query.eq('is_default', true);
      }

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query
          .order('sort_order', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final page = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
      categories.addAll(page);
      if (page.length < _pageSize) break;
    }

    return categories;
  }

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
      final categories = await _fetchCategoriesPageable(
        homeId: homeId,
        type: type,
      );

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
      throw Exception('must_login_first');
    }

    Map<String, dynamic>? existing;
    try {
      existing = await _client
          .from('categories')
          .select('id')
          .eq('home_id', homeId)
          .eq('name', name)
          .isFilter('deleted_at', null)
          .maybeSingle();
    } on PostgrestException {
      rethrow;
    } catch (_) {
      // Offline first run: local write below keeps the UI responsive, then the
      // queued server write will surface any duplicate constraint later.
    }

    if (existing != null) {
      throw Exception('category_name_exists');
    }

    final now = DateTime.now();
    final newCategory = CategoryModel(
      id: const Uuid().v4(),
      homeId: homeId,
      name: name,
      type: _parseCategoryType(type),
      icon: icon,
      color: color,
      sortOrder: sortOrder ?? 0,
      isDefault: false,
      createdBy: user.id,
      createdAt: now,
      updatedAt: now,
    );

    final current = await _localDataSource.getCategories(
      homeId: homeId,
      type: type,
    );
    final updated = [...current, newCategory]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _localDataSource.saveCategories(
      homeId: homeId,
      type: type,
      categories: updated,
    );
    LocalCacheNotifier.notify(homeId, 'categories');

    try {
      final response = await _client
          .from('categories')
          .upsert({
            'id': newCategory.id,
            'home_id': homeId,
            'name': name,
            'type': type,
            'icon': icon,
            'color': color,
            'sort_order': sortOrder ?? 0,
            'is_default': false,
            'created_by': user.id,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }, onConflict: 'id')
          .select()
          .single();

      final serverCategory = CategoryModel.fromJson(response);
      await _localDataSource.saveCategories(
        homeId: homeId,
        type: type,
        categories: [
          ...current.where((category) => category.id != newCategory.id),
          serverCategory,
        ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
      LocalCacheNotifier.notify(homeId, 'categories');
      return serverCategory;
    } on PostgrestException {
      await _softDeleteLocalCategory(newCategory.id);
      LocalCacheNotifier.notify(homeId, 'categories');
      rethrow;
    } catch (_) {
      await _queueDataSource.enqueueAction(
        actionType: ActionType.createCategory,
        entityType: EntityType.category,
        entityId: newCategory.id,
        homeId: homeId,
        payload: newCategory.toJson(),
      );
      return newCategory;
    }
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
      throw Exception('must_login_first');
    }

    final localCategory = await _localDataSource.getCategoryById(categoryId);
    if (localCategory?.isDefault == true) {
      throw Exception('cannot_edit_default_categories');
    }

    var homeId = localCategory?.homeId;
    if (homeId == null) {
      final category = await _client
          .from('categories')
          .select('is_default, home_id')
          .eq('id', categoryId)
          .single();

      if (category['is_default'] == true) {
        throw Exception('cannot_edit_default_categories');
      }
      homeId = category['home_id'] as String;
    }

    final now = DateTime.now();
    final updatedCategory =
        localCategory?.copyWithModel(
          name: name,
          icon: icon,
          color: color,
          sortOrder: sortOrder,
          updatedAt: now,
        ) ??
        CategoryModel(
          id: categoryId,
          homeId: homeId,
          name: name ?? '',
          type: CategoryType.shopping,
          icon: icon,
          color: color,
          sortOrder: sortOrder ?? 0,
          updatedAt: now,
        );

    final current = await _localDataSource.getCategories(homeId: homeId);
    await _localDataSource.saveCategories(
      homeId: homeId,
      categories:
          current.map((c) => c.id == categoryId ? updatedCategory : c).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
    LocalCacheNotifier.notify(homeId, 'categories');

    final updates = <String, dynamic>{'updated_at': now.toIso8601String()};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    try {
      final response = await _client
          .from('categories')
          .update(updates)
          .eq('id', categoryId)
          .select()
          .single();

      final serverCategory = CategoryModel.fromJson(response);
      final latest = await _localDataSource.getCategories(homeId: homeId);
      await _localDataSource.saveCategories(
        homeId: homeId,
        categories:
            latest.map((c) => c.id == categoryId ? serverCategory : c).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
      LocalCacheNotifier.notify(homeId, 'categories');
      return serverCategory;
    } on PostgrestException {
      rethrow;
    } catch (_) {
      await _queueDataSource.enqueueAction(
        actionType: ActionType.updateCategory,
        entityType: EntityType.category,
        entityId: categoryId,
        homeId: homeId,
        payload: {
          ...updates,
          'home_id': homeId,
          'base_updated_at': _baseUpdatedAt(localCategory),
        },
      );
      return updatedCategory;
    }
  }

  @override
  Future<void> deleteCategory({required String categoryId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final localCategory = await _localDataSource.getCategoryById(categoryId);
    if (localCategory?.isDefault == true) {
      throw Exception('cannot_delete_default_categories');
    }

    var homeId = localCategory?.homeId;
    if (homeId == null) {
      final category = await _client
          .from('categories')
          .select('is_default, home_id')
          .eq('id', categoryId)
          .single();

      if (category['is_default'] == true) {
        throw Exception('cannot_delete_default_categories');
      }
      homeId = category['home_id'] as String;
    }

    final deletedAt = DateTime.now();
    await _softDeleteLocalCategory(categoryId, deletedAt: deletedAt);
    LocalCacheNotifier.notify(homeId, 'categories');

    try {
      await _client
          .from('categories')
          .update({
            'deleted_at': deletedAt.toIso8601String(),
            'updated_at': deletedAt.toIso8601String(),
          })
          .eq('id', categoryId);
    } on PostgrestException {
      rethrow;
    } catch (_) {
      await _queueDataSource.enqueueAction(
        actionType: ActionType.deleteCategory,
        entityType: EntityType.category,
        entityId: categoryId,
        homeId: homeId,
        payload: {
          'id': categoryId,
          'home_id': homeId,
          'deleted_at': deletedAt.toIso8601String(),
          'base_updated_at': _baseUpdatedAt(localCategory),
        },
      );
    }
  }

  @override
  Future<CategoryModel?> getCategoryById({required String categoryId}) async {
    final cached = await _localDataSource.getCategoryById(categoryId);
    if (cached != null && cached.deletedAt == null) return cached;

    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('id', categoryId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      final category = CategoryModel.fromJson(response);
      await _localDataSource.saveCategories(
        homeId: category.homeId,
        type: category.type.name,
        categories: [category],
      );
      return category;
    } catch (_) {
      return cached;
    }
  }

  @override
  Stream<List<CategoryModel>> watchCategories({
    String? homeId,
    String? type,
  }) async* {
    Future<List<CategoryModel>> loadCache() async {
      return _localDataSource.getCategories(homeId: homeId, type: type);
    }

    // 1. Emit cached categories instantly (0 network requests, instant perceived loading)
    yield await loadCache();

    // 2. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if ((homeId == null || event.homeId == homeId) &&
          event.entityType == 'categories') {
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
        final localSyncTime = await _syncService.getLocalSyncTimeAsync(
          homeId,
          'categories',
        );
        final hasSyncedCategoriesBefore = await _syncService.isInitialSyncDone(
          homeId,
          'categories',
        );

        // Delta Sync check: pull only for first sync or newer server changes.
        if (!hasSyncedCategoriesBefore ||
            serverCategoriesMaxUpdate.isAfter(localSyncTime)) {
          final categories = await _fetchCategoriesPageable(
            homeId: homeId,
            includeDeleted: true,
          );

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
            await _syncService.updateLocalSyncTime(
              homeId,
              'categories',
              DateTime.now(),
            );
          }

          // Notify reactive streams
          LocalCacheNotifier.notify(homeId, 'categories');
        }
      }
    } catch (_) {
      rethrow;
    }
  }

  CategoryType _parseCategoryType(String value) {
    switch (value) {
      case 'inventory':
        return CategoryType.inventory;
      case 'expense':
        return CategoryType.expense;
      case 'shopping':
      default:
        return CategoryType.shopping;
    }
  }

  String? _baseUpdatedAt(CategoryModel? category) {
    final value = category?.updatedAt ?? category?.createdAt;
    return value?.toUtc().toIso8601String();
  }

  Future<void> _softDeleteLocalCategory(
    String categoryId, {
    DateTime? deletedAt,
  }) async {
    final localDataSource = _localDataSource;
    if (localDataSource is DriftCategoryLocalDataSource) {
      await localDataSource.softDeleteCategory(
        categoryId: categoryId,
        deletedAt: deletedAt,
      );
    }
  }
}
