import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../../domain/entities/shopping_item.dart';

class ListSummaryScreen extends ConsumerWidget {
  final String listId;

  const ListSummaryScreen({
    super.key,
    required this.listId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final listAsync = ref.watch(shoppingListByIdProvider(listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(listId));

    return Scaffold(
      appBar: AppBar(
        title: listAsync.when(
          data: (list) => Text(
            isArabic ? 'ملخص: ${list?.name ?? ''}' : 'Summary: ${list?.name ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => Text(isArabic ? 'ملخص القائمة' : 'List Summary'),
          error: (_, __) => Text(isArabic ? 'ملخص القائمة' : 'List Summary'),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return BeityEmptyState(
              title: isArabic ? 'القائمة فارغة' : 'List is Empty',
              message: isArabic ? 'لا توجد منتجات لعرض ملخص لها' : 'No items to show summary for',
              icon: Icons.summarize_outlined,
            );
          }
          return _buildSummary(context, items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => BeityEmptyState(
          title: isArabic ? 'حدث خطأ' : 'An error occurred',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Retry',
          onActionPressed: () => ref.invalidate(shoppingItemsProvider(listId)),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<ShoppingItem> items) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
          _buildProgressCard(context, totalItems, purchasedCount, completionPercentage, isArabic),
          AppSpacing.gapLG,
          if (totalPrice > 0) ...[
            _buildPriceCard(context, totalPrice, purchasedTotal, isArabic),
            AppSpacing.gapLG,
          ],
          _buildCategoryBreakdown(context, items, isArabic),
          AppSpacing.gapLG,
          if (unpurchasedItems.isNotEmpty) ...[
            _buildItemsList(context, isArabic ? 'للشراء' : 'To Buy', unpurchasedItems, isArabic),
            AppSpacing.gapLG,
          ],
          if (purchasedItems.isNotEmpty) ...[
            _buildItemsList(context, isArabic ? 'تم شراؤها' : 'Purchased', purchasedItems, isArabic),
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
    bool isArabic,
  ) {
    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'التقدم' : 'Progress',
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
              _buildStatItem(context, isArabic ? 'الإجمالي' : 'Total', '$total'),
              _buildStatItem(context, isArabic ? 'تم شراؤها' : 'Purchased', '$purchased'),
              _buildStatItem(context, isArabic ? 'متبقي' : 'Remaining', '${total - purchased}'),
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
    bool isArabic,
  ) {
    final remaining = total - purchased;

    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'التكلفة التقديرية' : 'Estimated Cost',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapMD,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceItem(context, isArabic ? 'الإجمالي' : 'Total', total, isArabic),
              _buildPriceItem(context, isArabic ? 'تم الشراء' : 'Purchased', purchased, isArabic),
              _buildPriceItem(context, isArabic ? 'متبقي' : 'Remaining', remaining, isArabic),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(BuildContext context, String label, double amount, bool isArabic) {
    return Column(
      children: [
        Text(
          isArabic ? '${amount.toStringAsFixed(2)} ر.س' : 'SAR ${amount.toStringAsFixed(2)}',
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

  Widget _buildCategoryBreakdown(BuildContext context, List<ShoppingItem> items, bool isArabic) {
    final categoryMap = <String, List<ShoppingItem>>{};
    
    for (final item in items) {
      final categoryId = item.categoryId ?? (isArabic ? 'بدون تصنيف' : 'Uncategorized');
      categoryMap.putIfAbsent(categoryId, () => []).add(item);
    }

    if (categoryMap.isEmpty) return const SizedBox.shrink();

    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'حسب التصنيف' : 'By Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapMD,
          ...categoryMap.entries.map((entry) {
            final purchased = entry.value.where((i) => i.isPurchased).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key),
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
  }

  Widget _buildItemsList(
    BuildContext context,
    String title,
    List<ShoppingItem> items,
    bool isArabic,
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
                    ? Text(isArabic 
                        ? 'الكمية: ${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(1)}' 
                        : 'Qty: ${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(1)}')
                    : null,
                trailing: item.hasPrice
                    ? Text(
                        item.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              )),
        ],
      ),
    );
  }
}
