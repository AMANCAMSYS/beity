import 'package:flutter/material.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../domain/entities/expense.dart';
import 'package:intl/intl.dart' as intl;

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = intl.DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return BeityCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: expense.isCancelled
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 24,
              color: expense.isCancelled
                  ? theme.colorScheme.outline
                  : theme.colorScheme.primary,
            ),
          ),
          AppSpacing.gapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: expense.isCancelled ? TextDecoration.lineThrough : null,
                    color: expense.isCancelled ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.gapXXS,
                Text(
                  dateFormat.format(expense.date),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapMD,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(expense.convertedAmount / 100).toStringAsFixed(2)} ${isArabic ? 'ر.س' : 'SAR'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: expense.isCancelled ? theme.colorScheme.outline : theme.colorScheme.primary,
                ),
              ),
              if (expense.isCancelled)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      isArabic ? 'ملغي' : 'Cancelled',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
