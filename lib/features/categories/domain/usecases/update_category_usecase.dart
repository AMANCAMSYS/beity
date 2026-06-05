import '../../../../core/errors/app_exception.dart';
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
      throw const ValidationException(message: 'please_enter_category_name_validation');
    }

    if (name != null && name.length > 100) {
      throw const ValidationException(message: 'category_name_too_long');
    }

    return _repository.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
    );
  }
}
