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
    final listAsync = ref.watch(shoppingListByIdProvider(listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(listId));

    return Scaffold(
      appBar: AppBar(
        title: listAsync.when(
          data: (list) => Text('ملخص: ${list?.name ?? ''}'),
          loading: () => const Text('ملخص القائمة'),
          error: (_, __) => const Text('ملخص القائمة'),
        ),
      ),
      body: itemsAsync.when(
        data: (items) => _buildSummary(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
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
          const SizedBox(height: 16),
          if (totalPrice > 0) ...[
            _buildPriceCard(context, totalPrice, purchasedTotal),
            const SizedBox(height: 16),
          ],
          _buildCategoryBreakdown(context, items),
          const SizedBox(height: 16),
          if (unpurchasedItems.isNotEmpty) ...[
            _buildItemsList(context, 'للشراء', unpurchasedItems),
            const SizedBox(height: 16),
          ],
          if (purchasedItems.isNotEmpty) ...[
            _buildItemsList(context, 'تم شراؤها', purchasedItems),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التقدم',
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
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? purchased / total : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(context, 'الإجمالي', '$total'),
                _buildStatItem(context, 'تم شراؤها', '$purchased'),
                _buildStatItem(context, 'متبقي', '${total - purchased}'),
              ],
            ),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التكلفة التقديرية',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceItem(context, 'الإجمالي', total),
                _buildPriceItem(context, 'تم الشراء', purchased),
                _buildPriceItem(context, 'متبقي', remaining),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(BuildContext context, String label, double amount) {
    return Column(
      children: [
        Text(
          '${amount.toStringAsFixed(2)} ر.س',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildCategoryBreakdown(BuildContext context, List<ShoppingItem> items) {
    final categoryMap = <String, List<ShoppingItem>>{};
    
    for (final item in items) {
      final categoryId = item.categoryId ?? 'بدون تصنيف';
      categoryMap.putIfAbsent(categoryId, () => []).add(item);
    }

    if (categoryMap.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حسب التصنيف',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...categoryMap.entries.map((entry) {
              final purchased = entry.value.where((i) => i.isPurchased).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text('$purchased/${entry.value.length}'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: entry.value.isNotEmpty
                            ? purchased / entry.value.length
                            : 0,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    String title,
    List<ShoppingItem> items,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...items.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.isPurchased
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.isPurchased ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  title: Text(item.name),
                  subtitle: item.quantity != 1
                      ? Text('الكمية: ${item.quantity}')
                      : null,
                  trailing: item.hasPrice
                      ? Text(item.formattedPrice)
                      : null,
                )),
          ],
        ),
      ),
    );
  }
}
