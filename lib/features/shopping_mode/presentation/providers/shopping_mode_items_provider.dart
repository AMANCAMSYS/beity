import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import 'shopping_mode_provider.dart';

class CategoryGroup {
  final String? categoryId;
  final String categoryName;
  final List<ShoppingItemModel> items;
  final bool allPurchased;

  const CategoryGroup({
    this.categoryId,
    required this.categoryName,
    required this.items,
    required this.allPurchased,
  });
}

final shoppingModeItemsProvider =
    Provider.family<AsyncValue<List<CategoryGroup>>, ({String listId, String? homeId})>((ref, params) {
  final itemsAsync = ref.watch(shoppingItemsProvider(params.listId));
  final categoriesAsync = ref.watch(categoriesProvider(params.homeId));
  final shoppingMode = ref.watch(shoppingModeProvider);

  return itemsAsync.when(
    data: (items) {
      final categories = categoriesAsync.valueOrNull ?? [];

      // Apply search filter
      var filteredItems = items;
      if (shoppingMode.searchQuery.isNotEmpty) {
        final query = shoppingMode.searchQuery.toLowerCase();
        filteredItems = items
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }

      // Group by category
      final Map<String?, List<ShoppingItemModel>> grouped = {};
      for (final item in filteredItems) {
        grouped.putIfAbsent(item.categoryId, () => []).add(item);
      }

      // Build category groups
      final List<CategoryGroup> groups = [];

      // Add named categories
      for (final entry in grouped.entries) {
        if (entry.key == null) continue;
        final category = categories.where((c) => c.id == entry.key).firstOrNull;
        final categoryName = category?.name ?? 'Other';
        final sortedItems = _sortItems(entry.value);
        final allPurchased = sortedItems.every((item) => item.isPurchased);
        groups.add(CategoryGroup(
          categoryId: entry.key,
          categoryName: categoryName,
          items: sortedItems,
          allPurchased: allPurchased,
        ));
      }

      // Add uncategorized items at the end
      if (grouped.containsKey(null)) {
        final sortedItems = _sortItems(grouped[null]!);
        final allPurchased = sortedItems.every((item) => item.isPurchased);
        groups.add(CategoryGroup(
          categoryId: null,
          categoryName: 'Other',
          items: sortedItems,
          allPurchased: allPurchased,
        ));
      }

      return AsyncData(groups);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

List<ShoppingItemModel> _sortItems(List<ShoppingItemModel> items) {
  final unpurchased = items.where((i) => !i.isPurchased).toList();
  final purchased = items.where((i) => i.isPurchased).toList();
  return [...unpurchased, ...purchased];
}

final shoppingModePurchasedCountProvider =
    Provider.family<int, String>((ref, listId) {
  final itemsAsync = ref.watch(shoppingItemsProvider(listId));
  return itemsAsync.when(
    data: (items) => items.where((item) => item.isPurchased).length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final shoppingModeTotalCountProvider =
    Provider.family<int, String>((ref, listId) {
  final itemsAsync = ref.watch(shoppingItemsProvider(listId));
  return itemsAsync.when(
    data: (items) => items.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final shoppingModeProgressProvider =
    Provider.family<double, String>((ref, listId) {
  final itemsAsync = ref.watch(shoppingItemsProvider(listId));
  return itemsAsync.when(
    data: (items) {
      if (items.isEmpty) return 0.0;
      double totalProgress = 0.0;
      for (final item in items) {
        if (item.isPurchased) {
          totalProgress += 1.0;
        } else if (item.quantity > 0 && item.purchasedQuantity > 0) {
          totalProgress += (item.purchasedQuantity / item.quantity).clamp(0.0, 1.0);
        }
      }
      return totalProgress / items.length;
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});
