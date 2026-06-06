import 'package:flutter/material.dart';

import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import '../models/list_detail_item.dart';
import 'category_header_tile.dart';
import '../../widgets/shopping_item_tile_widget.dart';
import '../../widgets/list_detail_search_bar.dart';
import '../../widgets/category_filter_widget.dart';
import '../../widgets/list_detail_summary_bar.dart';

class ListItemsSection extends StatelessWidget {
  final List<ListDetailItem> flattenedList;
  final bool isSearchVisible;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final List<CategoryModel> categories;
  final String? filterCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final String listId;
  final String homeId;
  final double unpurchasedTotal;
  final Map<String, String?> unitNames;
  final Map<String, DateTime> highlightedItems;
  final bool compactListMode;
  final bool hapticFeedback;
  final bool soundEffects;
  final void Function(String itemId, bool isPurchased) onTogglePurchased;
  final void Function(String itemId) onQuantityTap;
  final void Function(ShoppingItemModel item) onEdit;
  final void Function(ShoppingItemModel item) onDelete;
  final void Function(String? categoryId) onToggleCategory;
  final VoidCallback onClearFilters;

  const ListItemsSection({
    super.key,
    required this.flattenedList,
    required this.isSearchVisible,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.categories,
    required this.filterCategoryId,
    required this.onCategorySelected,
    required this.listId,
    required this.homeId,
    required this.unpurchasedTotal,
    required this.unitNames,
    required this.highlightedItems,
    required this.compactListMode,
    required this.hapticFeedback,
    required this.soundEffects,
    required this.onTogglePurchased,
    required this.onQuantityTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCategory,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (flattenedList.isEmpty) {
      return SawaEmptyState(
        title: context.translate('no_results'),
        message: context.translate('no_results_desc'),
        icon: Icons.search_off_rounded,
        actionText: context.translate('clear_filters'),
        onAction: onClearFilters,
      );
    }

    return Column(
      children: [
        if (isSearchVisible)
          ListDetailSearchBar(
            controller: searchController,
            searchQuery: searchQuery,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CategoryFilterWidget(
              categories: categories,
              selectedCategoryId: filterCategoryId,
              onCategorySelected: onCategorySelected,
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: flattenedList.length + 1,
            itemBuilder: (context, index) {
              if (index == flattenedList.length) {
                return const SizedBox(height: AppSpacing.md);
              }

              final listItem = flattenedList[index];

              if (listItem is CategoryHeaderItem) {
                return CategoryHeaderTile(
                  categoryName: listItem.categoryName,
                  unpurchasedCount: listItem.unpurchasedCount,
                  isExpanded: listItem.isExpanded,
                  onTap: () => onToggleCategory(listItem.categoryId),
                );
              } else if (listItem is ShoppingItemRow) {
                final item = listItem.item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ShoppingItemTileWidget(
                    item: item,
                    unitName: item.unitId != null
                        ? unitNames[item.unitId]
                        : null,
                    highlightUntil: highlightedItems[item.id],
                    showPendingIndicator: listItem.hasPending,
                    isCompact: compactListMode,
                    hapticsEnabled: hapticFeedback,
                    soundsEnabled: soundEffects,
                    onTogglePurchased: () =>
                        onTogglePurchased(item.id, !item.isPurchased),
                    onQuantityTap: () => onQuantityTap(item.id),
                    onEdit: () => onEdit(item),
                    onDelete: () => onDelete(item),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        ListDetailSummaryBar(
          listId: listId,
          homeId: homeId,
          unpurchasedTotal: unpurchasedTotal,
        ),
      ],
    );
  }
}
