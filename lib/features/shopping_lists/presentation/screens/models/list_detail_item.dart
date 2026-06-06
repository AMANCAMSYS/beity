import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';

sealed class ListDetailItem {}

class CategoryHeaderItem extends ListDetailItem {
  final String? categoryId;
  final String categoryName;
  final int unpurchasedCount;
  final bool isExpanded;

  CategoryHeaderItem({
    required this.categoryId,
    required this.categoryName,
    required this.unpurchasedCount,
    required this.isExpanded,
  });
}

class ShoppingItemRow extends ListDetailItem {
  final ShoppingItemModel item;
  final bool hasPending;

  ShoppingItemRow({required this.item, required this.hasPending});
}
