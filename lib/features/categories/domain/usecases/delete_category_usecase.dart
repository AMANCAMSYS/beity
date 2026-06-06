import '../../data/repositories/category_repository.dart';

class DeleteCategoryUseCase {
  final CategoryRepository _repository;

  DeleteCategoryUseCase(this._repository);

  Future<void> call({required String categoryId}) async {
    await _repository.deleteCategory(categoryId: categoryId);
  }
}
