import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/shopping_mode_session_model.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class ShoppingExitSummary extends ConsumerWidget {
  final ShoppingModeSessionModel session;
  final List<ShoppingItemModel> purchasedItems;
  final String? homeId;
  final VoidCallback onDismiss;

  const ShoppingExitSummary({
    super.key,
    required this.session,
    required this.purchasedItems,
    this.homeId,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider(homeId));
    final categories = categoriesAsync.valueOrNull ?? [];

    // Group purchased items by category
    final Map<String?, List<ShoppingItemModel>> grouped = {};
    for (final item in purchasedItems) {
      grouped.putIfAbsent(item.categoryId, () => []).add(item);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Shopping Complete!',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${session.itemsPurchasedCount} of ${session.itemsTotalCount} items purchased',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (purchasedItems.isNotEmpty) ...[
                    Text(
                      'Purchased Items',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...grouped.entries.map((entry) {
                      final category = categories
                          .where((c) => c.id == entry.key)
                          .firstOrNull;
                      final categoryName = category?.name ?? 'Other';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              categoryName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          ...entry.value.map((item) => ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                title: Text(item.name),
                                subtitle: item.purchasedBy != null
                                    ? Text('Purchased by user')
                                    : null,
                              )),
                        ],
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onDismiss,
                    child: const Text('Return to List'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
