import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../domain/entities/subscription_plan.dart';
import '../providers/subscription_plans_provider.dart';

class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(subscriptionPlansProvider);
    final currentEntitlement = ref.watch(
      currentSubscriptionEntitlementProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.translate('subscription_plans'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          const _BillingHeader(),
          AppSpacing.gapLG,
          for (final plan in plans) ...[
            _PlanCard(
              plan: plan,
              isCurrent: currentEntitlement.planId == plan.id,
            ),
            AppSpacing.gapLG,
          ],
          _PurchaseReadinessNote(),
        ],
      ),
    );
  }
}

class _BillingHeader extends StatelessWidget {
  const _BillingHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SawaCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          AppSpacing.gapLG,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('billing_header_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.translate('billing_header_subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;

  const _PlanCard({required this.plan, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SawaCard(
      hasBorder: plan.isRecommended,
      backgroundColor: plan.isRecommended
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.translate(plan.titleKey),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (plan.badgeKey != null) ...[
                          AppSpacing.gapSM,
                          _PlanBadge(label: context.translate(plan.badgeKey!)),
                        ],
                      ],
                    ),
                    AppSpacing.gapXS,
                    Text(
                      context.translate(plan.subtitleKey),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMD,
              Text(
                context.translate(plan.priceLabelKey),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          AppSpacing.gapLG,
          for (final featureKey in plan.featureKeys)
            _PlanFeature(label: context.translate(featureKey)),
          AppSpacing.gapLG,
          _PlanLimits(plan: plan),
          AppSpacing.gapLG,
          SawaButton(
            text: isCurrent
                ? context.translate('current_plan')
                : context.translate('billing_purchase_coming_soon'),
            icon: isCurrent
                ? Icons.check_circle_rounded
                : Icons.lock_clock_rounded,
            type: isCurrent ? SawaButtonType.secondary : SawaButtonType.primary,
            fullWidth: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;

  const _PlanBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  final String label;

  const _PlanFeature({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 18,
          ),
          AppSpacing.gapSM,
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLimits extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PlanLimits({required this.plan});

  @override
  Widget build(BuildContext context) {
    final limits = plan.limits;
    final values = [
      _limitText(
        context,
        limits.hasUnlimitedHomes
            ? 'billing_limit_unlimited_homes'
            : 'billing_limit_homes',
        limits.maxHomes.toString(),
      ),
      _limitText(
        context,
        'billing_limit_members',
        limits.maxMembersPerHome.toString(),
      ),
      _limitText(
        context,
        limits.hasUnlimitedActiveLists
            ? 'billing_limit_unlimited_active_lists'
            : 'billing_limit_active_lists',
        limits.maxActiveLists.toString(),
      ),
      _limitText(
        context,
        'billing_limit_ai',
        limits.aiSuggestionsPerMonth.toString(),
      ),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.map((text) => _LimitChip(label: text)).toList(),
    );
  }

  String _limitText(BuildContext context, String key, String value) {
    return context.translate(key, arguments: {'value': value});
  }
}

class _LimitChip extends StatelessWidget {
  final String label;

  const _LimitChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PurchaseReadinessNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      context.translate('billing_readiness_note'),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
    );
  }
}
