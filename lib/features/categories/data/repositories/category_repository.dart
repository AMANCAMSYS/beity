import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories({
    String? homeId,
    String? type,
  });

  Future<CategoryModel> createCategory({
    required String homeId,
    required String name,
    required String type,
    String? icon,
    String? color,
    int? sortOrder,
  });

  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  });

  Future<void> deleteCategory({
    required String categoryId,
  });

  Future<CategoryModel?> getCategoryById({
    required String categoryId,
  });

  Stream<List<CategoryModel>> watchCategories({
    String? homeId,
    String? type,
  });
}
