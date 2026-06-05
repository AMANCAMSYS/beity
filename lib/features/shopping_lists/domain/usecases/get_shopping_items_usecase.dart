import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class GetShoppingItemsUseCase {
  final ShoppingListRepository _repository;

  GetShoppingItemsUseCase(this._repository);

  Future<List<ShoppingItemModel>> call({required String listId}) async {
    return _repository.getShoppingItems(listId: listId);
  }
}
