import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import 'category_repository.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client;

  SupabaseCategoryRepository(this._client);

  @override
  Future<List<CategoryModel>> getCategories({
    String? homeId,
    String? type,
  }) async {
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
    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
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

    return CategoryModel.fromJson(response);
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
        .select('is_default')
        .eq('id', categoryId)
        .single();

    if (category['is_default'] == true) {
      throw Exception('لا يمكن تعديل التصنيفات الافتراضية');
    }

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

    return CategoryModel.fromJson(response);
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
        .select('is_default')
        .eq('id', categoryId)
        .single();

    if (category['is_default'] == true) {
      throw Exception('لا يمكن حذف التصنيفات الافتراضية');
    }

    await _client
        .from('categories')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', categoryId);
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
  }) {
    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('sort_order', ascending: true)
        .map((response) => response
            .map((json) => CategoryModel.fromJson(json))
            .where((cat) =>
                cat.deletedAt == null &&
                (cat.isDefault || (homeId != null && homeId.isNotEmpty && cat.homeId == homeId)) &&
                (type == null || cat.type.name == type))
            .toList());
  }
}
