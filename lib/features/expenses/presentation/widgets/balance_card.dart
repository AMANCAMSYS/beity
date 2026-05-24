import 'package:flutter/material.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../domain/entities/balance.dart';

class BalanceCard extends StatelessWidget {
  final Balance balance;

  const BalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final amount = balance.absoluteAmount / 100;

    return BeityCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // Debtor (Owes money)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'مدين' : 'Debtor',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapXXS,
                Text(
                  balance.getDebtor(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Amount and Arrow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                  size: 20,
                ),
                AppSpacing.gapXXS,
                Text(
                  amount.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                Text(
                  isArabic ? 'ر.س' : 'SAR',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Creditor (Is owed money)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isArabic ? 'دائن' : 'Creditor',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapXXS,
                Text(
                  balance.getCreditor(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
