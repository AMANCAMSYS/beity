import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../../core/accessibility/semantics_helpers.dart';

class ShoppingItemCard extends StatelessWidget {
  final ShoppingItemModel item;
  final String? unitName;
  final VoidCallback onTap;
  final VoidCallback? onQuantityTap;
  final String? purchaserName;

  const ShoppingItemCard({
    super.key,
    required this.item,
    this.unitName,
    required this.onTap,
    this.onQuantityTap,
    this.purchaserName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isPurchased = item.isPurchased;

    return Semantics(
      label: AccessibilityHelpers.shoppingItemLabel(
        name: item.name,
        quantity: item.quantity,
        unit: unitName,
        isPurchased: isPurchased,
      ),
      button: true,
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: isPurchased
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Purchase indicator
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPurchased
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isPurchased
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isPurchased
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Item details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration:
                                  isPurchased ? TextDecoration.lineThrough : null,
                              color: isPurchased
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                              fontWeight:
                                  isPurchased ? FontWeight.normal : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isPurchased && purchaserName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              purchaserName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quantity
                    if (item.quantity > 1 || item.unitId != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onQuantityTap,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatQuantity(item, isArabic),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatQuantity(ShoppingItemModel item, bool isArabic) {
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(1);
    
    if (unitName == null || unitName!.isEmpty) return qty;
    return '$qty $unitName';
  }
}
