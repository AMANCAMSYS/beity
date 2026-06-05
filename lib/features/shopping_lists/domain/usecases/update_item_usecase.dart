import '../../data/repositories/shopping_list_repository.dart';
import '../entities/shopping_item.dart';

class UpdateItemUseCase {
  final ShoppingListRepository _repository;

  UpdateItemUseCase(this._repository);

  Future<ShoppingItem> call({
    required String itemId,
    String? name,
    double? quantity,
    Object? unitId = shoppingFieldUnchanged,
    Object? categoryId = shoppingFieldUnchanged,
    Object? price = shoppingFieldUnchanged,
    Object? notes = shoppingFieldUnchanged,
  }) async {
    if (name != null && name.trim().isEmpty) {
      throw Exception('product_name_required');
    }

    if (quantity != null && quantity <= 0) {
      throw Exception('quantity_must_be_greater_than_zero');
    }

    final normalizedNotes = identical(notes, shoppingFieldUnchanged)
        ? shoppingFieldUnchanged
        : (notes as String?)?.trim();

    return _repository.updateShoppingItem(
      itemId: itemId,
      name: name?.trim(),
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
      price: price,
      notes: normalizedNotes == '' ? null : normalizedNotes,
    );
  }
}
