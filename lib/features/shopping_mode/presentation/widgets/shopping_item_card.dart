import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../../core/accessibility/semantics_helpers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';

class ShoppingItemCard extends StatefulWidget {
  final ShoppingItemModel item;
  final String? unitName;
  final VoidCallback onTap;
  final VoidCallback? onQuantityTap;
  final String? purchaserName;
  final bool hapticsEnabled;

  const ShoppingItemCard({
    super.key,
    required this.item,
    this.unitName,
    required this.onTap,
    this.onQuantityTap,
    this.purchaserName,
    this.hapticsEnabled = true,
  });

  @override
  State<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends State<ShoppingItemCard> {
  bool? _optimisticPurchased;
  bool _isProcessing = false;

  @override
  void didUpdateWidget(ShoppingItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemIdentityChanged = oldWidget.item.id != widget.item.id;
    final purchaseStateChanged =
        oldWidget.item.isPurchased != widget.item.isPurchased;

    if (itemIdentityChanged || purchaseStateChanged) {
      _optimisticPurchased = null;
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isPurchased = _optimisticPurchased ?? widget.item.isPurchased;
    final hasPartialPurchase =
        widget.item.purchasedQuantity > 0 &&
        widget.item.purchasedQuantity < widget.item.quantity &&
        !isPurchased;

    return Semantics(
      label: AccessibilityHelpers.shoppingItemLabel(
        name: widget.item.name,
        quantity: widget.item.quantity,
        unit: widget.unitName,
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
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    )
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
              onTap: _isProcessing
                  ? null
                  : () {
                      final tappedItemId = widget.item.id;
                      final willBePurchased = !isPurchased;
                      if (widget.hapticsEnabled) {
                        if (willBePurchased) {
                          HapticFeedback.mediumImpact();
                        } else {
                          HapticFeedback.selectionClick();
                        }
                      }
                      setState(() {
                        _optimisticPurchased = willBePurchased;
                        _isProcessing = true;
                      });

                      // Add a brief delay to show the checkmark before dropping
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted && widget.item.id == tappedItemId) {
                          widget.onTap();
                        }
                      });
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Purchase indicator
                    _buildLeadingIcon(theme, isPurchased, hasPartialPurchase),
                    const SizedBox(width: 12),
                    // Item details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration: isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isPurchased
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                              fontWeight: isPurchased
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.item.quantity > 1 ||
                              widget.item.unitId != null ||
                              hasPartialPurchase) ...[
                            const SizedBox(height: 4),
                            _buildQuantitySubtitle(
                              theme,
                              hasPartialPurchase,
                              isArabic,
                            ),
                          ],
                          if (isPurchased && widget.purchaserName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.purchaserName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Side Button for Partial Purchase
                    if (widget.item.quantity > 1 && !isPurchased) ...[
                      IconButton(
                        icon: Icon(
                          Icons.pie_chart_outline,
                          size: 22,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: widget.onQuantityTap,
                        tooltip: context.translate('partially_purchased'),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(
    ThemeData theme,
    bool isPurchased,
    bool hasPartialPurchase,
  ) {
    if (hasPartialPurchase) {
      final progress = widget.item.purchasedQuantity / widget.item.quantity;
      return SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.warning,
                ),
              ),
            ),
            const Text(
              '½',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPurchased ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isPurchased
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      child: isPurchased
          ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
          : null,
    );
  }

  Widget _buildQuantitySubtitle(
    ThemeData theme,
    bool hasPartialPurchase,
    bool isArabic,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPartialPurchase) ...[
          const Icon(
            Icons.pie_chart_outline,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatQuantity(widget.item, isArabic),
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasPartialPurchase
                ? AppColors.warning
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: hasPartialPurchase ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  String _formatQuantity(ShoppingItemModel item, bool isArabic) {
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(1);

    final purchasedQty =
        item.purchasedQuantity == item.purchasedQuantity.roundToDouble()
        ? item.purchasedQuantity.toInt().toString()
        : item.purchasedQuantity.toStringAsFixed(1);

    final showPartial =
        item.purchasedQuantity > 0 && item.purchasedQuantity < item.quantity;
    final qtyString = showPartial ? '$purchasedQty / $qty' : qty;

    if (widget.unitName == null || widget.unitName!.isEmpty) return qtyString;
    return '$qtyString ${widget.unitName}';
  }
}
