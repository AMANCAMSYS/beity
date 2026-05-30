import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class PurchasedItemInput {
  final String name;
  final double quantity;
  final String? unitId;
  final String? categoryId;

  PurchasedItemInput({
    required this.name,
    required this.quantity,
    this.unitId,
    this.categoryId,
  });
}

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

  Future<void> callBatch({
    required String homeId,
    required List<PurchasedItemInput> items,
  }) async {
    if (items.isEmpty) return;

    // 1. Fetch all existing inventory items for the home to perform matching locally
    final existingItems = await _inventoryRepository.getInventoryItems(homeId: homeId);
    
    // Create a helper map for quick lookup by lowercase name and unitId
    final existingMap = <String, InventoryItemModel>{};
    for (final item in existingItems) {
      final key = '${item.name.toLowerCase()}_${item.unitId ?? "null"}';
      existingMap[key] = item;
    }

    final futures = <Future<dynamic>>[];

    for (final item in items) {
      final key = '${item.name.toLowerCase()}_${item.unitId ?? "null"}';
      final existing = existingMap[key];

      if (existing != null) {
        final newQty = existing.quantity + item.quantity;
        futures.add(() async {
          await _inventoryRepository.updateInventoryItem(
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
        }());
      } else {
        futures.add(() async {
          final newItem = await _inventoryRepository.createInventoryItem(
            homeId: homeId,
            name: item.name,
            quantity: item.quantity,
            unitId: item.unitId,
            categoryId: item.categoryId,
          );
          await _inventoryRepository.createTransaction(
            inventoryItemId: newItem.id,
            homeId: homeId,
            previousQuantity: 0,
            newQuantity: item.quantity,
            changeReason: 'shopping_restock',
          );
        }());
      }
    }

    // Run all updates/inserts and transactions in parallel
    await Future.wait(futures);
  }
}
