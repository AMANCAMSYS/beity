import '../entities/category.dart';
import '../../data/repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository _repository;

  UpdateCategoryUseCase(this._repository);

  Future<Category> call({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    // Validate name if provided
    if (name != null && name.isEmpty) {
      throw Exception('يرجى إدخال اسم التصنيف');
    }

    if (name != null && name.length > 100) {
      throw Exception('اسم التصنيف طويل جداً');
    }

    return await _repository.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
    );
  }
}
