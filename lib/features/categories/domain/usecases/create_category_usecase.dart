import '../../../../core/errors/app_exception.dart';
import '../entities/category.dart';
import '../../data/repositories/category_repository.dart';

class CreateCategoryUseCase {
  final CategoryRepository _repository;

  CreateCategoryUseCase(this._repository);

  Future<Category> call({
    required String homeId,
    required String name,
    required String type,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    // Validate name
    if (name.isEmpty) {
      throw const ValidationException(
        message: 'please_enter_category_name_validation',
      );
    }

    if (name.length > 100) {
      throw const ValidationException(message: 'category_name_too_long');
    }

    // Validate type
    if (!_isValidType(type)) {
      throw const ValidationException(message: 'invalid_category_type');
    }

    return _repository.createCategory(
      homeId: homeId,
      name: name,
      type: type,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
    );
  }

  bool _isValidType(String type) {
    return ['shopping', 'inventory', 'expense'].contains(type);
  }
}
