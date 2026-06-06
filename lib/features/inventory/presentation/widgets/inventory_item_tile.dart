import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../domain/entities/inventory_item.dart';
import 'low_stock_badge.dart';

class InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  final String? unitName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onQuantityIncrement;
  final VoidCallback? onQuantityDecrement;

  const InventoryItemTile({
    super.key,
    required this.item,
    this.unitName,
    this.onTap,
    this.onDelete,
    this.onQuantityIncrement,
    this.onQuantityDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: SawaCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerLow,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isLowStock) ...[
                          AppSpacing.gapSM,
                          const LowStockBadge(),
                        ],
                      ],
                    ),
                    if (unitName != null ||
                        (item.notes != null && item.notes!.isNotEmpty)) ...[
                      AppSpacing.gapXXS,
                      _buildSubtitle(context, theme),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapMD,
              _buildQuantityControls(context, theme),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) {
      return content;
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
            AppSpacing.gapXXS,
            Text(
              context.translate('delete'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) => onDelete?.call(),
      child: content,
    );
  }

  Widget _buildSubtitle(BuildContext context, ThemeData theme) {
    final parts = <String>[];
    if (unitName != null) parts.add(unitName!);
    if (item.notes != null && item.notes!.isNotEmpty) parts.add(item.notes!);
    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        AppSpacing.gapXXS,
        Expanded(
          child: Text(
            parts.join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: onQuantityDecrement == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onQuantityDecrement?.call();
                  },
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              _formatQuantity(item.quantity),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onTap: onQuantityIncrement == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onQuantityIncrement?.call();
                  },
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double q) {
    if (q == q.roundToDouble() && q < 1000) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            AppSpacing.gapMD,
            Text(
              context.translate('delete_product'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          context.translate(
            'delete_item_confirm',
            arguments: {'name': item.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.translate('cancel'),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SawaButton(
            width: 100,
            text: context.translate('delete'),
            onPressed: () => Navigator.pop(context, true),
            type: SawaButtonType.primary,
            icon: Icons.delete_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}
