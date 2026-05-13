import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class AddInventoryItemUseCase {
  final InventoryRepository _repository;

  AddInventoryItemUseCase(this._repository);

  Future<InventoryItemModel> call({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? minQuantity,
    String? notes,
  }) async {
    // Check for duplicate
    final existing = await _repository.findDuplicateItem(
      homeId: homeId,
      name: name,
      unitId: unitId,
    );

    if (existing != null) {
      // Merge quantities
      final newQty = existing.quantity + quantity;
      final updated = await _repository.updateInventoryItem(
        itemId: existing.id,
        quantity: newQty,
      );
      await _repository.createTransaction(
        inventoryItemId: existing.id,
        homeId: homeId,
        previousQuantity: existing.quantity,
        newQuantity: newQty,
        changeReason: 'manual_update',
      );
      return updated;
    }

    // Create new item
    final item = await _repository.createInventoryItem(
      homeId: homeId,
      name: name,
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
      minQuantity: minQuantity,
      notes: notes,
    );
    await _repository.createTransaction(
      inventoryItemId: item.id,
      homeId: homeId,
      previousQuantity: 0,
      newQuantity: quantity,
      changeReason: 'initial_add',
    );
    return item;
  }
}
