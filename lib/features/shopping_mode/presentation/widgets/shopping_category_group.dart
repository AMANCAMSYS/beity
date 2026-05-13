import 'package:flutter/material.dart';
import '../providers/shopping_mode_items_provider.dart';
import 'shopping_item_card.dart';

class ShoppingCategoryGroup extends StatelessWidget {
  final CategoryGroup group;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Function(String itemId) onItemTap;
  final Function(String itemId)? onQuantityTap;

  const ShoppingCategoryGroup({
    super.key,
    required this.group,
    required this.isCollapsed,
    required this.onToggle,
    required this.onItemTap,
    this.onQuantityTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        GestureDetector(
          onTap: onToggle,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  group.categoryName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.items.where((i) => i.isPurchased).length}/${group.items.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (group.allPurchased) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
        // Items
        if (!isCollapsed)
          ...group.items.map((item) => ShoppingItemCard(
                item: item,
                onTap: () => onItemTap(item.id),
                onQuantityTap: onQuantityTap != null
                    ? () => onQuantityTap!(item.id)
                    : null,
              )),
      ],
    );
  }
}
