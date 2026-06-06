import '../../data/repositories/inventory_repository.dart';

class DeleteInventoryItemUseCase {
  final InventoryRepository _repository;

  DeleteInventoryItemUseCase(this._repository);

  Future<void> call({required String itemId, required String homeId}) async {
    final item = await _repository.getInventoryItemById(itemId: itemId);
    if (item == null) return;

    await _repository.deleteInventoryItem(itemId: itemId);
    await _repository.createTransaction(
      inventoryItemId: itemId,
      homeId: homeId,
      previousQuantity: item.quantity,
      newQuantity: 0,
      changeReason: 'delete',
    );
  }
}
