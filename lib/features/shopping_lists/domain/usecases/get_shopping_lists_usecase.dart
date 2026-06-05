import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class GetShoppingListsUseCase {
  final ShoppingListRepository _repository;

  GetShoppingListsUseCase(this._repository);

  Future<List<ShoppingListModel>> call({
    required String homeId,
    String? status,
  }) async {
    return _repository.getShoppingLists(homeId: homeId, status: status);
  }
}
