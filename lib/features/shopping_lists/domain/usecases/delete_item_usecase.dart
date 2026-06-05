import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../entities/shopping_item.dart';

class DeleteItemUseCase {
  final ShoppingListRepository _repository;

  DeleteItemUseCase(this._repository);

  /// Delete an item and return its data for undo purposes.
  Future<ShoppingItem?> callAndReturn({required String itemId}) async {
    final item = await _repository.getShoppingItemById(itemId: itemId);
    await _repository.deleteShoppingItem(itemId: itemId);
    return item;
  }

  Future<void> call({required String itemId}) async {
    await _repository.deleteShoppingItem(itemId: itemId);
  }

  /// Re-create a previously deleted item (undo) by clearing soft delete.
  Future<void> restoreItem({required ShoppingItem item}) async {
    await _repository.restoreShoppingItem(item: item as ShoppingItemModel);
  }
}
