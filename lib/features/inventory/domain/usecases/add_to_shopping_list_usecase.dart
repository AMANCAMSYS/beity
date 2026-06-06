import '../../data/repositories/inventory_repository.dart';
import '../../../shopping_lists/data/repositories/shopping_list_repository.dart';

class AddToShoppingListUseCase {
  final InventoryRepository _inventoryRepository;
  final ShoppingListRepository _shoppingListRepository;

  AddToShoppingListUseCase(
    this._inventoryRepository,
    this._shoppingListRepository,
  );

  Future<void> call({
    required String inventoryItemId,
    required String homeId,
    required String shoppingListId,
  }) async {
    final item = await _inventoryRepository.getInventoryItemById(
      itemId: inventoryItemId,
    );
    if (item == null) throw Exception('error_item_not_found_in_inventory');

    // Calculate suggested restock quantity
    final suggestedQty = item.minQuantity != null
        ? (item.minQuantity! * 2) - item.quantity
        : 1.0;

    // Check if item already exists in shopping list
    final existingItems = await _shoppingListRepository.getShoppingItems(
      listId: shoppingListId,
    );
    final existing = existingItems.where(
      (si) =>
          si.name.toLowerCase() == item.name.toLowerCase() &&
          si.unitId == item.unitId,
    );

    if (existing.isNotEmpty) {
      // Update existing shopping item quantity
      final si = existing.first;
      await _shoppingListRepository.updateShoppingItem(
        itemId: si.id,
        quantity: si.quantity + suggestedQty,
      );
    } else {
      // Create new shopping item
      await _shoppingListRepository.createShoppingItem(
        listId: shoppingListId,
        name: item.name,
        quantity: suggestedQty,
        unitId: item.unitId,
        categoryId: item.categoryId,
      );
    }
  }
}
