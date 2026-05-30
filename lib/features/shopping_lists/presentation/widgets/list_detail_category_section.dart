import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../data/models/shopping_item_model.dart';
import 'shopping_item_tile_widget.dart';

class ListDetailCategorySection extends ConsumerWidget {
  final String? categoryId;
  final List<ShoppingItemModel> items;
  final bool isExpanded;
  final String homeId;
  final Map<String, String> unitNames;
  final String listId;
  final Map<String, DateTime> highlightedItems;
  final ValueChanged<bool> onExpansionChanged;
  final Function(String itemId, bool isPurchased) onTogglePurchased;
  final Function(ShoppingItemModel item) onDelete;
  final bool isCompact;
  final bool hapticsEnabled;
  final bool soundsEnabled;

  const ListDetailCategorySection({
    super.key,
    required this.categoryId,
    required this.items,
    required this.isExpanded,
    required this.homeId,
    required this.unitNames,
    required this.listId,
    required this.highlightedItems,
    required this.onExpansionChanged,
    required this.onTogglePurchased,
    required this.onDelete,
    required this.isCompact,
    required this.hapticsEnabled,
    required this.soundsEnabled,
  });

  String _getCategoryName(BuildContext context, WidgetRef ref) {
    if (categoryId == null) return context.translate('uncategorized');

    final categoriesAsync = ref.read(categoriesProvider(homeId));
    return categoriesAsync.when(
      data: (categories) {
        final cat = categories.where((c) => c.id == categoryId).firstOrNull;
        return cat?.name ?? context.translate('uncategorized');
      },
      loading: () => context.translate('loading'),
      error: (error, stackTrace) => context.translate('uncategorized'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryName = _getCategoryName(context, ref);
    final unpurchasedCount = items.where((i) => !i.isPurchased).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onExpansionChanged(!isExpanded),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  size: 24,
                ),
                AppSpacing.gapXS,
                Text(
                  categoryName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapSM,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Text(
                    '$unpurchasedCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...items.map((item) {
            final queueEntries = ref.watch(queueEntriesProvider(homeId));
            final hasPending = queueEntries.when(
              data: (entries) =>
                  entries.any((e) => e.entityId == item.id && e.isPending),
              loading: () => false,
              error: (error, stackTrace) => false,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ShoppingItemTileWidget(
                item: item,
                unitName: item.unitId != null ? unitNames[item.unitId] : null,
                highlightUntil: highlightedItems[item.id],
                showPendingIndicator: hasPending,
                isCompact: isCompact,
                hapticsEnabled: hapticsEnabled,
                soundsEnabled: soundsEnabled,
                onTogglePurchased: () => ActionDebouncer.execute(
                  () => onTogglePurchased(item.id, !item.isPurchased),
                ),
                onEdit: () => ActionDebouncer.execute(
                  () => context.push(
                    '/shopping-list/$listId/edit-item/${item.id}',
                  ),
                ),
                onDelete: () => ActionDebouncer.execute(() => onDelete(item)),
              ),
            );
          }),
        AppSpacing.gapSM,
      ],
    );
  }
}
