import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class AddPurchasedToInventoryUseCase {
  final InventoryRepository _inventoryRepository;

  AddPurchasedToInventoryUseCase(this._inventoryRepository);

  Future<InventoryItemModel> call({
    required String homeId,
    required String name,
    required double quantity,
    String? unitId,
    String? categoryId,
  }) async {
    // Check for existing item
    final existing = await _inventoryRepository.findDuplicateItem(
      homeId: homeId,
      name: name,
      unitId: unitId,
    );

    if (existing != null) {
      // Merge quantities
      final newQty = existing.quantity + quantity;
      final updated = await _inventoryRepository.updateInventoryItem(
        itemId: existing.id,
        quantity: newQty,
      );
      await _inventoryRepository.createTransaction(
        inventoryItemId: existing.id,
        homeId: homeId,
        previousQuantity: existing.quantity,
        newQuantity: newQty,
        changeReason: 'shopping_restock',
      );
      return updated;
    }

    // Create new inventory item
    final item = await _inventoryRepository.createInventoryItem(
      homeId: homeId,
      name: name,
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
    );
    await _inventoryRepository.createTransaction(
      inventoryItemId: item.id,
      homeId: homeId,
      previousQuantity: 0,
      newQuantity: quantity,
      changeReason: 'shopping_restock',
    );
    return item;
  }
}
