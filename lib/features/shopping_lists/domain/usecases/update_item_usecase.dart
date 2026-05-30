import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class UpdateItemUseCase {
  final ShoppingListRepository _repository;

  UpdateItemUseCase(this._repository);

  Future<ShoppingItemModel> call({
    required String itemId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  }) async {
    if (name != null && name.trim().isEmpty) {
      throw Exception('اسم المنتج مطلوب');
    }

    if (quantity != null && quantity <= 0) {
      throw Exception('الكمية يجب أن تكون أكبر من صفر');
    }

    return _repository.updateShoppingItem(
      itemId: itemId,
      name: name?.trim(),
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
      price: price,
      notes: notes?.trim(),
    );
  }
}
