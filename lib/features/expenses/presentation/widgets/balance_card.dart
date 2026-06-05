import 'package:flutter/material.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../domain/entities/balance.dart';

class BalanceCard extends StatelessWidget {
  final Balance balance;
  final Map<String, String> memberNames;
  final VoidCallback? onSettle;

  const BalanceCard({
    super.key,
    required this.balance,
    this.memberNames = const {},
    this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = balance.absoluteAmount / 100;
    final debtorName =
        memberNames[balance.getDebtor()] ??
        context.translate('unknown_member');
    final creditorName =
        memberNames[balance.getCreditor()] ??
        context.translate('unknown_member');

    return SawaCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              // Debtor (Owes money)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate('debtor'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapXXS,
                    Text(
                      debtorName,
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
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
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
                      context.translate('currency_symbol'),
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
                      context.translate('creditor'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapXXS,
                    Text(
                      creditorName,
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
          if (onSettle != null) ...[
            AppSpacing.gapMD,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: Text(context.translate('record_payment')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
