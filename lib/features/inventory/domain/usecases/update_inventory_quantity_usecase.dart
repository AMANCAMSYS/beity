import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class UpdateInventoryQuantityUseCase {
  final InventoryRepository _repository;

  UpdateInventoryQuantityUseCase(this._repository);

  Future<InventoryItemModel?> call({
    required String itemId,
    required String homeId,
    required double newQuantity,
    String changeReason = 'manual_update',
  }) async {
    final item = await _repository.getInventoryItemById(itemId: itemId);
    if (item == null) return null;

    if (newQuantity <= 0) {
      // Let the repository detect the out-of-stock threshold before the item
      // is removed from the active inventory list.
      await _repository.updateInventoryItem(itemId: itemId, quantity: 0);
      await _repository.deleteInventoryItem(itemId: itemId);
      await _repository.createTransaction(
        inventoryItemId: itemId,
        homeId: homeId,
        previousQuantity: item.quantity,
        newQuantity: 0,
        changeReason: 'zero_removal',
      );
      return null;
    }

    final updated = await _repository.updateInventoryItem(
      itemId: itemId,
      quantity: newQuantity,
    );
    await _repository.createTransaction(
      inventoryItemId: itemId,
      homeId: homeId,
      previousQuantity: item.quantity,
      newQuantity: newQuantity,
      changeReason: changeReason,
    );
    return updated;
  }
}
