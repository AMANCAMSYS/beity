import '../entities/category.dart';
import '../../data/repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<Category>> call({
    String? homeId,
    String? type,
  }) async {
    return await _repository.getCategories(
      homeId: homeId,
      type: type,
    );
  }
}
