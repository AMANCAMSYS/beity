import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class CreateShoppingListUseCase {
  final ShoppingListRepository _repository;

  CreateShoppingListUseCase(this._repository);

  Future<ShoppingListModel> call({
    required String homeId,
    required String name,
    String? description,
    String? icon,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('list_name_required');
    }

    return _repository.createShoppingList(
      homeId: homeId,
      name: name.trim(),
      description: description?.trim(),
      icon: icon,
    );
  }
}
