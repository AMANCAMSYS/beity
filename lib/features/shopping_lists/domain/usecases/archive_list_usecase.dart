import '../../data/repositories/shopping_list_repository.dart';

class ArchiveListUseCase {
  final ShoppingListRepository _repository;

  ArchiveListUseCase(this._repository);

  Future<void> call({
    required String listId,
  }) async {
    await _repository.updateShoppingList(
      listId: listId,
      status: 'archived',
    );
  }

  Future<void> restore({
    required String listId,
  }) async {
    await _repository.updateShoppingList(
      listId: listId,
      status: 'active',
    );
  }
}
