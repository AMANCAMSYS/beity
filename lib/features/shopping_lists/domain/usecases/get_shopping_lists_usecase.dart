import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class GetShoppingListsUseCase {
  final ShoppingListRepository _repository;

  GetShoppingListsUseCase(this._repository);

  Future<List<ShoppingListModel>> call({
    required String homeId,
    String? status,
  }) async {
    return await _repository.getShoppingLists(
      homeId: homeId,
      status: status,
    );
  }

  Stream<List<ShoppingListModel>> watch({
    required String homeId,
  }) {
    return _repository.watchShoppingLists(homeId: homeId);
  }
}
