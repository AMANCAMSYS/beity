import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class UpdateItemPurchaseStateUseCase {
  final ShoppingListRepository _repository;

  UpdateItemPurchaseStateUseCase(this._repository);

  Future<ShoppingItemModel> call({
    required String itemId,
    required double purchasedQuantity,
  }) {
    if (purchasedQuantity < 0) {
      throw ArgumentError.value(
        purchasedQuantity,
        'purchasedQuantity',
        'must be greater than or equal to zero',
      );
    }

    return _repository.updateItemPurchaseState(
      itemId: itemId,
      purchasedQuantity: purchasedQuantity,
    );
  }
}
