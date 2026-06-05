import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

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
    Provider.family<
      AsyncValue<List<CategoryGroup>>,
      ({String listId, String? homeId})
    >((ref, params) {
      final itemsAsync = params.homeId == null || params.homeId!.isEmpty
          ? ref.watch(shoppingItemsProvider(params.listId))
          : ref.watch(
              shoppingItemsForHomeProvider((
                listId: params.listId,
                homeId: params.homeId!,
              )),
            );
      final categoriesAsync = ref.watch(categoriesProvider(params.homeId));

      return itemsAsync.when(
        data: (items) {
          final categories = categoriesAsync.value ?? [];
          final categoryById = {for (final c in categories) c.id: c};

          // Group by category
          final Map<String?, List<ShoppingItemModel>> grouped = {};
          for (final item in items) {
            grouped.putIfAbsent(item.categoryId, () => []).add(item);
          }

          // Build category groups
          final List<CategoryGroup> groups = [];

          // Add named categories
          for (final entry in grouped.entries) {
            if (entry.key == null) continue;
            final category = categoryById[entry.key];
            final categoryName = category?.name ?? '_uncategorized';
            final sortedItems = _sortItems(entry.value);
            final allPurchased = sortedItems.every((item) => item.isPurchased);
            groups.add(
              CategoryGroup(
                categoryId: entry.key,
                categoryName: categoryName,
                items: sortedItems,
                allPurchased: allPurchased,
              ),
            );
          }

          // Add uncategorized items at the end
          if (grouped.containsKey(null)) {
            final sortedItems = _sortItems(grouped[null]!);
            final allPurchased = sortedItems.every((item) => item.isPurchased);
            groups.add(
              CategoryGroup(
                categoryId: null,
                categoryName: '_uncategorized',
                items: sortedItems,
                allPurchased: allPurchased,
              ),
            );
          }

          return AsyncData(groups);
        },
        loading: () => const AsyncLoading(),
        error: (error, stack) => AsyncError(error, stack),
      );
    });

  List<ShoppingItemModel> _sortItems(List<ShoppingItemModel> items) {
    return items..sort((a, b) {
      // 1. Purchased status first (unpurchased at top)
      if (a.isPurchased != b.isPurchased) {
        return a.isPurchased ? 1 : -1;
      }

      // 2. If both are purchased, sort by recently purchased
      if (a.isPurchased) {
        final aTime = a.purchasedAt ?? a.updatedAt;
        final bTime = b.purchasedAt ?? b.updatedAt;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime); // descending
        }
        return 0;
      }

      // 3. If both are unpurchased, sort by priority
      final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
      final aPriority = priorityOrder[a.priority] ?? 2;
      final bPriority = priorityOrder[b.priority] ?? 2;
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // 4. Fallback to name alphabetical
      return a.name.compareTo(b.name);
    });
  }

final shoppingModePurchasedCountProvider = Provider.family<int, String>((
  ref,
  listId,
) {
  final itemsAsync = ref.watch(shoppingItemsProvider(listId));
  return itemsAsync.when(
    data: (items) => items.where((item) => item.isPurchased).length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final shoppingModeTotalCountProvider = Provider.family<int, String>((
  ref,
  listId,
) {
  final itemsAsync = ref.watch(shoppingItemsProvider(listId));
  return itemsAsync.when(
    data: (items) => items.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final shoppingModeProgressProvider = Provider.family<double, String>((
  ref,
  listId,
) {
  final itemsAsync = ref.watch(shoppingItemsProvider(listId));
  return itemsAsync.when(
    data: (items) {
      if (items.isEmpty) return 0.0;
      double totalProgress = 0.0;
      for (final item in items) {
        if (item.isPurchased) {
          totalProgress += 1.0;
        } else if (item.quantity > 0 && item.purchasedQuantity > 0) {
          totalProgress += (item.purchasedQuantity / item.quantity).clamp(
            0.0,
            1.0,
          );
        }
      }
      return totalProgress / items.length;
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});

final shoppingModePurchasedCountForHomeProvider =
    Provider.family<int, ({String listId, String homeId})>((ref, params) {
      final itemsAsync = ref.watch(shoppingItemsForHomeProvider(params));
      return itemsAsync.when(
        data: (items) => items.where((item) => item.isPurchased).length,
        loading: () => 0,
        error: (error, stack) => 0,
      );
    });

final shoppingModeTotalCountForHomeProvider =
    Provider.family<int, ({String listId, String homeId})>((ref, params) {
      final itemsAsync = ref.watch(shoppingItemsForHomeProvider(params));
      return itemsAsync.when(
        data: (items) => items.length,
        loading: () => 0,
        error: (error, stack) => 0,
      );
    });

final shoppingModeProgressForHomeProvider =
    Provider.family<double, ({String listId, String homeId})>((ref, params) {
      final itemsAsync = ref.watch(shoppingItemsForHomeProvider(params));
      return itemsAsync.when(
        data: (items) {
          if (items.isEmpty) return 0.0;
          double totalProgress = 0.0;
          for (final item in items) {
            if (item.isPurchased) {
              totalProgress += 1.0;
            } else if (item.quantity > 0 && item.purchasedQuantity > 0) {
              totalProgress += (item.purchasedQuantity / item.quantity).clamp(
                0.0,
                1.0,
              );
            }
          }
          return totalProgress / items.length;
        },
        loading: () => 0.0,
        error: (error, stack) => 0.0,
      );
    });
