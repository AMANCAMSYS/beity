import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_empty_state.dart';
import '../../presentation/providers/shopping_mode_provider.dart';
import '../../presentation/providers/shopping_mode_items_provider.dart';
import '../widgets/shopping_category_group.dart';
import '../../../../core/utils/action_debouncer.dart';

class ShoppingModeItemsList extends StatelessWidget {
  final String listId;
  final String homeId;
  final List<CategoryGroup> groups;
  final Map<String, String> unitNames;
  final String? filterCategoryId;
  final String searchQuery;
  final ShoppingModeState shoppingMode;
  final bool hapticsEnabled;
  final VoidCallback onToggleCategory;
  final void Function(String itemId, bool isPurchased) onItemTap;
  final void Function(String itemId) onQuantityTap;
  final VoidCallback onRetry;

  const ShoppingModeItemsList({
    super.key,
    required this.listId,
    required this.homeId,
    required this.groups,
    required this.unitNames,
    required this.filterCategoryId,
    required this.searchQuery,
    required this.shoppingMode,
    required this.hapticsEnabled,
    required this.onToggleCategory,
    required this.onItemTap,
    required this.onQuantityTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    var filteredGroups = groups;

    if (filterCategoryId != null) {
      filteredGroups = groups
          .where((g) => g.categoryId == filterCategoryId)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filteredGroups = filteredGroups
          .map((group) {
            final filteredItems = group.items
                .where(
                  (item) => item.name.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();
            return CategoryGroup(
              categoryId: group.categoryId,
              categoryName: group.categoryName,
              items: filteredItems,
              allPurchased: filteredItems.every((i) => i.isPurchased),
            );
          })
          .where((g) => g.items.isNotEmpty)
          .toList();
    }

    if (filteredGroups.isEmpty) {
      return SawaEmptyState(
        title: searchQuery.isNotEmpty
            ? context.translate('no_results_found')
            : filterCategoryId != null
            ? context.translate('no_items_in_category')
            : context.translate('no_items_in_list'),
        message: searchQuery.isNotEmpty || filterCategoryId != null
            ? context.translate('filter_msg_adjust')
            : context.translate('filter_msg_empty'),
        icon: searchQuery.isNotEmpty || filterCategoryId != null
            ? Icons.search_off_rounded
            : Icons.shopping_cart_outlined,
        actionText: searchQuery.isNotEmpty || filterCategoryId != null
            ? context.translate('clear_filters')
            : null,
        onAction: searchQuery.isNotEmpty || filterCategoryId != null
            ? onRetry
            : null,
      );
    }

    return ListView.builder(
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        final categoryId = group.categoryId ?? 'uncategorized';

        final bool isCollapsed = shoppingMode.isCategoryCollapsed(
          categoryId,
          fallback: group.allPurchased,
        );

        return ShoppingCategoryGroup(
          key: ValueKey(categoryId),
          group: group,
          unitNames: unitNames,
          isCollapsed: isCollapsed,
          hapticsEnabled: hapticsEnabled,
          onToggle: () =>
              ActionDebouncer.execute(() async => onToggleCategory()),
          onItemTap: (itemId, isPurchased) => ActionDebouncer.execute(
            () async => onItemTap(itemId, isPurchased),
          ),
          onQuantityTap: (itemId) =>
              ActionDebouncer.execute(() async => onQuantityTap(itemId)),
        );
      },
    );
  }
}
