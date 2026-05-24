import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';

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

  double get _step {
    // Fractional units (kg, liters) use 0.5 step; whole units use 1
    // This will be refined with actual unit data
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              final newQty = (quantity - _step).clamp(0.0, double.infinity);
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
                  _formatQuantity(quantity, isArabic),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (unitId != null)
                  Text(
                    isArabic ? 'الكمية' : 'Quantity',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(quantity + _step);
            },
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double q, bool isArabic) {
    if (q == q.roundToDouble() && q < 1000) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
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
          child: Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
