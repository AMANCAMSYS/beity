import 'package:flutter/material.dart';
import 'package:beity/core/localization/app_localizations.dart';
import '../providers/shopping_mode_items_provider.dart';
import 'shopping_item_card.dart';

class ShoppingCategoryGroup extends StatelessWidget {
  final CategoryGroup group;
  final Map<String, String> unitNames;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Function(String itemId) onItemTap;
  final Function(String itemId)? onQuantityTap;
  final bool hapticsEnabled;

  const ShoppingCategoryGroup({
    super.key,
    required this.group,
    this.unitNames = const {},
    required this.isCollapsed,
    required this.onToggle,
    required this.onItemTap,
    this.onQuantityTap,
    this.hapticsEnabled = true,
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
                      ? (Directionality.of(context) == TextDirection.rtl
                          ? Icons.keyboard_arrow_left
                          : Icons.keyboard_arrow_right)
                      : Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  group.categoryName == 'Other' 
                      ? context.translate('other') 
                      : group.categoryName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.translate('items_ratio', arguments: {'purchased': group.items.where((i) => i.isPurchased).length.toString(), 'total': group.items.length.toString()}),
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
                unitName: item.unitId != null ? unitNames[item.unitId] : null,
                onTap: () => onItemTap(item.id),
                onQuantityTap: onQuantityTap != null
                    ? () => onQuantityTap!(item.id)
                    : null,
                hapticsEnabled: hapticsEnabled,
              )),
      ],
    );
  }
}
