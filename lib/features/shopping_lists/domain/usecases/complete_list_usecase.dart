import '../../data/repositories/shopping_list_repository.dart';

class CompleteListUseCase {
  final ShoppingListRepository _repository;

  CompleteListUseCase(this._repository);

  Future<void> call({required String listId}) async {
    await _repository.updateShoppingList(listId: listId, status: 'completed');
  }
}
