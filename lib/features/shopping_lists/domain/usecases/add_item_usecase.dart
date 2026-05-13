import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

enum AddItemResult { success, duplicateWarning, error }

class AddItemUseCase {
  final ShoppingListRepository _repository;

  AddItemUseCase(this._repository);

  /// Check if an item with the same name already exists in the list.
  Future<bool> checkDuplicate({
    required String listId,
    required String name,
  }) async {
    final items = await _repository.getShoppingItems(listId: listId);
    return items.any(
      (item) => item.name.toLowerCase() == name.trim().toLowerCase(),
    );
  }

  Future<ShoppingItemModel> call({
    required String listId,
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? currency,
    String? notes,
    bool skipDuplicateCheck = false,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('اسم المنتج مطلوب');
    }

    if (quantity <= 0) {
      throw Exception('الكمية يجب أن تكون أكبر من صفر');
    }

    // Duplicate check
    if (!skipDuplicateCheck) {
      final isDuplicate = await checkDuplicate(
        listId: listId,
        name: name,
      );
      if (isDuplicate) {
        throw DuplicateItemException(name.trim());
      }
    }

    final item = await _repository.createShoppingItem(
      listId: listId,
      name: name.trim(),
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
      price: price,
      currency: currency,
      notes: notes?.trim(),
    );

    // Auto-create or update template
    await _repository.syncTemplateOnAdd(
      homeId: homeId,
      name: name.trim(),
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
    );

    return item;
  }
}

class DuplicateItemException implements Exception {
  final String itemName;
  DuplicateItemException(this.itemName);

  @override
  String toString() => 'duplicate:$itemName';
}
