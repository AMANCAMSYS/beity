import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import '../../../homes/data/models/home_member_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../domain/entities/settlement.dart';
import '../providers/balance_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/settlement_form.dart';
import '../../../../core/localization/app_localizations.dart';

class BalancesScreen extends ConsumerWidget {
  final String homeId;

  const BalancesScreen({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(balancesProvider(homeId));
    final membersAsync = ref.watch(homeMembersProvider(homeId));
    final settlementsAsync = ref.watch(settlementsProvider(homeId));
    final theme = Theme.of(context);
    final memberNames = membersAsync.when(
      data: (members) => _memberNames(context, members),
      loading: () => const <String, String>{},
      error: (_, _) => const <String, String>{},
    );
    final membersLoading = membersAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.translate('balances_settlements'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: membersLoading
          ? const Center(child: CircularProgressIndicator())
          : balancesAsync.when(
              data: (balances) {
                if (balances.isEmpty) {
                  return SawaEmptyState(
                    title: context.translate('all_accounts_settled'),
                    message: context.translate('all_accounts_settled_msg'),
                    icon: Icons.check_circle_outline_rounded,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  children: [
                    for (final balance in balances)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BalanceCard(
                          balance: balance,
                          memberNames: memberNames,
                          onSettle: () => _showSettlementSheet(
                            context,
                            balance.getDebtor(),
                            balance.getCreditor(),
                            balance.absoluteAmount,
                            memberNames,
                          ),
                        ),
                      ),
                    AppSpacing.gapLG,
                    _buildSettlementHistory(
                      context,
                      settlementsAsync,
                      memberNames,
                      theme,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => SawaEmptyState(
                title: context.translate('error_title'),
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
                onAction: () => ref.invalidate(balancesProvider(homeId)),
              ),
            ),
    );
  }

  Map<String, String> _memberNames(
    BuildContext context,
    List<HomeMemberModel> members,
  ) {
    return {
      for (final member in members)
        member.userId: (member.userName?.trim().isNotEmpty ?? false)
            ? member.userName!.trim()
            : ((member.userEmail?.trim().isNotEmpty ?? false)
                  ? member.userEmail!.trim()
                  : context.translate('member')),
      for (final member in members)
        member.id: (member.userName?.trim().isNotEmpty ?? false)
            ? member.userName!.trim()
            : ((member.userEmail?.trim().isNotEmpty ?? false)
                  ? member.userEmail!.trim()
                  : context.translate('member')),
    };
  }

  String _memberName(
    BuildContext context,
    Map<String, String> memberNames,
    String memberId,
  ) {
    return memberNames[memberId] ?? context.translate('unknown_member');
  }

  void _showSettlementSheet(
    BuildContext context,
    String fromMember,
    String toMember,
    int maxAmount,
    Map<String, String> memberNames,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final availableHeight =
            mediaQuery.size.height -
            mediaQuery.padding.top -
            mediaQuery.viewInsets.bottom;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight.clamp(280.0, mediaQuery.size.height),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                           context.translate('record_payment'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.gapXS,
                        Text(
                          context.translate('pays_to_label', arguments: {
                            'from': _memberName(context, memberNames, fromMember),
                            'to': _memberName(context, memberNames, toMember),
                          }),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.gapLG,
                        SettlementForm(
                          homeId: homeId,
                          fromMember: fromMember,
                          toMember: toMember,
                          maxAmount: maxAmount,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettlementHistory(
    BuildContext context,
    AsyncValue<List<Settlement>> settlementsAsync,
    Map<String, String> memberNames,
    ThemeData theme,
  ) {
    return settlementsAsync.when(
      data: (settlements) {
        if (settlements.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate('recent_settlements'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapMD,
            for (final settlement in settlements.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  tileColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  leading: const Icon(Icons.payments_rounded),
                  title: Text(
                    context.translate('paid_to_label', arguments: {
                      'from': _memberName(context, memberNames, settlement.fromMember),
                      'to': _memberName(context, memberNames, settlement.toMember),
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${settlement.date.day}/${settlement.date.month}/${settlement.date.year}',
                  ),
                  trailing: Text(
                    '${(settlement.amount / 100).toStringAsFixed(2)} ${context.translate('currency_symbol')}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
