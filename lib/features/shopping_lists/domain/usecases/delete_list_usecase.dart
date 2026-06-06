import '../../data/repositories/shopping_list_repository.dart';

class DeleteListUseCase {
  final ShoppingListRepository _repository;

  DeleteListUseCase(this._repository);

  Future<void> call({required String listId}) async {
    await _repository.deleteShoppingList(listId: listId);
  }
}
