import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_list_repository.dart';

class MarkItemPurchasedUseCase {
  final ShoppingListRepository _repository;

  MarkItemPurchasedUseCase(this._repository);

  Future<ShoppingItemModel> call({
    required String itemId,
    required bool isPurchased,
  }) async {
    return await _repository.markItemPurchased(
      itemId: itemId,
      isPurchased: isPurchased,
    );
  }
}
