import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/services/sync_service.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/supabase_category_repository.dart';

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  return DriftCategoryLocalDataSource();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = SupabaseService.client;
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SupabaseCategoryRepository(client, localDataSource, syncService);
});

final categoriesProvider = FutureProvider.family<List<CategoryModel>, String?>((
  ref,
  homeId,
) async {
  if (homeId != null && homeId.isEmpty) {
    throw Exception('error_home_not_selected');
  }
  final repo = ref.read(categoryRepositoryProvider);
  return repo.getCategories(homeId: homeId);
});

final categoriesByTypeProvider =
    FutureProvider.family<
      List<CategoryModel>,
      ({String? homeId, String? type})
    >((ref, params) async {
      if (params.homeId != null && params.homeId!.isEmpty) {
        throw Exception('error_home_not_selected');
      }
      final repo = ref.read(categoryRepositoryProvider);
      return repo.getCategories(homeId: params.homeId, type: params.type);
    });

final categoriesStreamProvider = StreamProvider.autoDispose
    .family<List<CategoryModel>, String?>((ref, homeId) {
      if (homeId != null && homeId.isEmpty) {
        return Stream.value([]);
      }
      final repo = ref.read(categoryRepositoryProvider);
      return repo.watchCategories(homeId: homeId);
    });

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repo;

  CategoryNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<CategoryModel> createCategory({
    required String homeId,
    required String name,
    required String type,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final category = await _repo.createCategory(
        homeId: homeId,
        name: name,
        type: type,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );
      state = const AsyncValue.data(null);
      return category;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final category = await _repo.updateCategory(
        categoryId: categoryId,
        name: name,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );
      state = const AsyncValue.data(null);
      return category;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteCategory({required String categoryId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCategory(categoryId: categoryId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
      final repo = ref.read(categoryRepositoryProvider);
      return CategoryNotifier(repo);
    });
