import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class GetInventoryItemsUseCase {
  final InventoryRepository _repository;

  GetInventoryItemsUseCase(this._repository);

  Future<List<InventoryItemModel>> call({required String homeId}) {
    return _repository.getInventoryItems(homeId: homeId);
  }

  Map<String?, List<InventoryItemModel>> groupByCategory(
      List<InventoryItemModel> items) {
    final map = <String?, List<InventoryItemModel>>{};
    for (final item in items) {
      map.putIfAbsent(item.categoryId, () => []).add(item);
    }
    return map;
  }
}
