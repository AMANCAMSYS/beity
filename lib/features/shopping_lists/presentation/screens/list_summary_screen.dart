import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../../domain/entities/shopping_item.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class ListSummaryScreen extends ConsumerWidget {
  final String listId;

  const ListSummaryScreen({
    super.key,
    required this.listId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(shoppingListByIdProvider(listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(listId));

    return Scaffold(
      appBar: AppBar(
        title: listAsync.when(
          data: (list) => Text(
            context.translate('summary_title', arguments: {'name': list?.name ?? ''}),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => Text(context.translate('list_summary')),
          error: (e, s) => Text(context.translate('list_summary')),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return BeityEmptyState(
              title: context.translate('list_empty'),
              message: context.translate('no_items_summary'),
              icon: Icons.summarize_outlined,
            );
          }
          return _buildSummary(context, items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => BeityEmptyState(
          title: context.translate('error_title'),
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(shoppingItemsProvider(listId)),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<ShoppingItem> items) {
    final unpurchasedItems = items.where((i) => !i.isPurchased).toList();
    final purchasedItems = items.where((i) => i.isPurchased).toList();
    
    final totalItems = items.length;
    final purchasedCount = purchasedItems.length;
    final completionPercentage = totalItems > 0
        ? (purchasedCount / totalItems * 100).round()
        : 0;

    final totalPrice = items
        .where((i) => i.hasPrice)
        .fold<double>(0, (sum, i) => sum + (i.price! * i.quantity));
    
    final purchasedTotal = purchasedItems
        .where((i) => i.hasPrice)
        .fold<double>(0, (sum, i) => sum + (i.price! * i.quantity));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(context, totalItems, purchasedCount, completionPercentage),
          AppSpacing.gapLG,
          if (totalPrice > 0) ...[
            _buildPriceCard(context, totalPrice, purchasedTotal),
            AppSpacing.gapLG,
          ],
          _buildCategoryBreakdown(context, items),
          AppSpacing.gapLG,
          if (unpurchasedItems.isNotEmpty) ...[
            _buildItemsList(context, context.translate('to_buy'), unpurchasedItems),
            AppSpacing.gapLG,
          ],
          if (purchasedItems.isNotEmpty) ...[
            _buildItemsList(context, context.translate('purchased'), purchasedItems),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    int total,
    int purchased,
    int percentage,
  ) {
    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.translate('progress'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          AppSpacing.gapMD,
          LinearProgressIndicator(
            value: total > 0 ? purchased / total : 0,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          AppSpacing.gapMD,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(context, context.translate('total'), '$total'),
              _buildStatItem(context, context.translate('purchased'), '$purchased'),
              _buildStatItem(context, context.translate('remaining'), '${total - purchased}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(
    BuildContext context,
    double total,
    double purchased,
  ) {
    final remaining = total - purchased;

    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.translate('estimated_cost'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapMD,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceItem(context, context.translate('total'), total),
              _buildPriceItem(context, context.translate('purchased_cost'), purchased),
              _buildPriceItem(context, context.translate('remaining'), remaining),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(BuildContext context, String label, double amount) {
    return Column(
      children: [
        Text(
          '${amount.toStringAsFixed(2)} ${context.translate('currency_symbol')}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<ShoppingItem> items) {
    final categoryMap = <String?, List<ShoppingItem>>{};
    
    for (final item in items) {
      categoryMap.putIfAbsent(item.categoryId, () => []).add(item);
    }

    if (categoryMap.isEmpty) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, _) {
        // Get homeId from the list
        final listAsync = ref.watch(shoppingListByIdProvider(listId));
        final homeId = listAsync.valueOrNull?.homeId ?? '';
        final categoriesAsync = ref.watch(categoriesProvider(homeId));
        
        final categoryNames = <String, String>{};
        categoriesAsync.whenData((categories) {
          for (final cat in categories) {
            categoryNames[cat.id] = cat.name == 'Other' ? context.translate('other') : cat.name;
          }
        });

        return BeityCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('by_category'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.gapMD,
              ...categoryMap.entries.map((entry) {
                final categoryId = entry.key;
                final categoryName = categoryId != null
                    ? (categoryNames[categoryId] ?? context.translate('unknown_category'))
                    : context.translate('uncategorized');
                final purchased = entry.value.where((i) => i.isPurchased).length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(categoryName),
                      ),
                      Text('$purchased/${entry.value.length}'),
                      AppSpacing.gapMD,
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: entry.value.isNotEmpty
                              ? purchased / entry.value.length
                              : 0,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    String title,
    List<ShoppingItem> items,
  ) {
    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${items.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapMD,
          ...items.map((item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.isPurchased
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: item.isPurchased 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                    color: item.isPurchased ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                  ),
                ),
                subtitle: item.quantity != 1 || item.unitId != null
                    ? Text(context.translate('qty_label', arguments: {
                        'qty': item.quantity == item.quantity.roundToDouble() 
                            ? item.quantity.toInt().toString() 
                            : item.quantity.toStringAsFixed(1),
                      }))
                    : null,
                trailing: item.hasPrice
                    ? Text(
                        '${(item.price! * item.quantity).toStringAsFixed(2)} ${context.translate('currency_symbol')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              )),
        ],
      ),
    );
  }
}
