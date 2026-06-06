import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class QuantityAdjusterWidget extends StatelessWidget {
  final double quantity;
  final String? unitId;
  final ValueChanged<double> onChanged;

  const QuantityAdjusterWidget({
    super.key,
    required this.quantity,
    this.unitId,
    required this.onChanged,
  });

  double get step {
    if (unitId == null) return 1.0;
    final lowerUnit = unitId!.toLowerCase();
    if (lowerUnit.contains('kg') ||
        lowerUnit.contains('كجم') ||
        lowerUnit.contains('كيلو') ||
        lowerUnit.contains('kilo') ||
        lowerUnit.contains('g') ||
        lowerUnit.contains('جرام') ||
        lowerUnit.contains('gram') ||
        lowerUnit.contains('liter') ||
        lowerUnit.contains('litre') ||
        lowerUnit.contains('لتر') ||
        lowerUnit.contains('ltr')) {
      return 0.25;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              final newQty = (quantity - step).clamp(0.0, double.infinity);
              onChanged(newQty);
            },
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatQuantity(quantity),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (unitId != null)
                  Text(
                    context.translate('quantity'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(quantity + step);
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
    return q.toString().replaceAll(RegExp(r'\.0$'), '');
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(icon, size: 24, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
