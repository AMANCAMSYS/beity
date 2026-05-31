import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';

class ShoppingGuideDialog extends StatelessWidget {
  const ShoppingGuideDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ShoppingGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.translate;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xxl,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            AppSpacing.gapXL,
            // Title
            Text(
              t('shopping_guide_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXL,
            // Guide Items
            _buildGuideItem(
              context,
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              title: t('guide_single_tap'),
              description: t('guide_single_tap_desc'),
            ),
            AppSpacing.gapLG,
            _buildGuideItem(
              context,
              icon: Icons.layers_outlined,
              color: theme.colorScheme.primary,
              title: t('guide_multi_quantity'),
              description: t('guide_multi_quantity_desc'),
            ),
            AppSpacing.gapLG,
            _buildGuideItem(
              context,
              icon: Icons.pie_chart_outline,
              color: AppColors.warning,
              title: t('guide_partial_progress'),
              description: t('guide_partial_progress_desc'),
            ),
            AppSpacing.gapXL,
            // Got it button
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                t('got_it'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        AppSpacing.gapMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXS,
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(theme.brightness),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
