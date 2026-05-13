import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class DeleteItemUseCase {
  final ShoppingListRepository _repository;

  DeleteItemUseCase(this._repository);

  /// Delete an item and return its data for undo purposes.
  Future<ShoppingItemModel?> callAndReturn({
    required String itemId,
  }) async {
    final item = await _repository.getShoppingItemById(itemId: itemId);
    await _repository.deleteShoppingItem(itemId: itemId);
    return item;
  }

  Future<void> call({
    required String itemId,
  }) async {
    await _repository.deleteShoppingItem(itemId: itemId);
  }

  /// Re-create a previously deleted item (undo).
  Future<void> restoreItem({
    required ShoppingItemModel item,
  }) async {
    await _repository.createShoppingItem(
      listId: item.shoppingListId,
      name: item.name,
      quantity: item.quantity,
      unitId: item.unitId,
      categoryId: item.categoryId,
      price: item.price,
      notes: item.notes,
    );
  }
}
