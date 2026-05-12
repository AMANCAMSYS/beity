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
      throw Exception('يرجى إدخال اسم التصنيف');
    }

    if (name.length > 100) {
      throw Exception('اسم التصنيف طويل جداً');
    }

    // Validate type
    if (!_isValidType(type)) {
      throw Exception('نوع التصنيف غير صالح');
    }

    return await _repository.createCategory(
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
