import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import '../providers/expense_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../../../homes/data/models/home_member_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/core/errors/error_formatter.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;
  final String homeId;

  const ExpenseDetailScreen({super.key, required this.expenseId, required this.homeId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(expenseByIdProvider(widget.expenseId));
    final splitsAsync = ref.watch(expenseSplitsProvider(widget.expenseId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.translate('expense_details'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    context.translate('edit_feature_soon'),
                  ),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            onPressed: _isDeleting
                ? null
                : () => _confirmDelete(context),
          ),
        ],
      ),
      body: expenseAsync.when(
        data: (expense) {
          if (expense == null) {
            return SawaEmptyState(
              title: context.translate('expense_not_found'),
              message: context.translate('expense_not_found_desc'),
              icon: Icons.receipt_long_rounded,
              actionText: context.translate('go_back'),
              onAction: () => context.pop(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final membersAsync = ref.watch(
                    homeMembersProvider(widget.homeId),
                  );
                  return _buildExpenseHeader(
                    context,
                    expense,
                    membersAsync,
                    theme,
                  );
                },
              ),
              AppSpacing.gapLG,
              Consumer(
                builder: (context, ref, _) {
                  final membersAsync = ref.watch(
                    homeMembersProvider(widget.homeId),
                  );
                  return _buildSplitsSection(
                    context,
                    splitsAsync,
                    membersAsync,
                    theme,
                  );
                },
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
          onAction: () => ref.invalidate(expenseByIdProvider(widget.expenseId)),
        ),
      ),
    );
  }

  Map<String, String> _memberNames(
    List<HomeMemberModel> members,
  ) {
    return {
      for (final member in members)
        member.userId: (member.userName?.trim().isNotEmpty ?? false)
            ? member.userName!.trim()
            : ((member.userEmail?.trim().isNotEmpty ?? false)
                  ? member.userEmail!.trim()
                  : context.translate('member')),
    };
  }

  Widget _buildExpenseHeader(
    BuildContext context,
    Expense expense,
    AsyncValue<List<HomeMemberModel>> membersAsync,
    ThemeData theme,
  ) {
    final memberNames = membersAsync.value != null
        ? _memberNames(membersAsync.value!)
        : const <String, String>{};
    final payerName =
        memberNames[expense.paidBy] ??
        context.translate('member');

    return SawaCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
                    Text(
                      expense.description,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapSM,
                    Text(
                      '${(expense.convertedAmount / 100).toStringAsFixed(2)} ${context.translate('currency_symbol')}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: expense.isCancelled
                            ? theme.colorScheme.outline
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (expense.isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      AppSpacing.gapXXS,
                      Text(
                        context.translate('cancelled'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          AppSpacing.gapXL,
          const Divider(),
          AppSpacing.gapXL,
          _buildDetailRow(
            Icons.calendar_today_rounded,
            context.translate('date'),
            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            theme,
          ),
          _buildDetailRow(
            Icons.info_outline_rounded,
            context.translate('status'),
            expense.isCancelled
                ? context.translate('cancelled')
                : context.translate('active'),
            theme,
            color: expense.isCancelled
                ? theme.colorScheme.error
                : AppColors.success,
          ),
          _buildDetailRow(
            Icons.account_circle_rounded,
            context.translate('paid_by_label'),
            payerName,
            theme,
          ),
          if (expense.categoryId != null)
            _buildDetailRow(
              Icons.category_rounded,
              context.translate('category_label'),
              context.translate('category'),
              theme,
            ),
          if (expense.currencyCode != 'SAR')
            _buildDetailRow(
              Icons.currency_exchange_rounded,
              context.translate('original_currency'),
              expense.currencyCode,
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          AppSpacing.gapLG,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXXS,
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitsSection(
    BuildContext context,
    AsyncValue<List<ExpenseSplit>> splitsAsync,
    AsyncValue<List<HomeMemberModel>> membersAsync,
    ThemeData theme,
  ) {
    final memberNames = membersAsync.value != null
        ? _memberNames(membersAsync.value!)
        : const <String, String>{};

    return splitsAsync.when(
      data: (splits) {
        if (splits.isEmpty) {
          return SawaCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapMD,
                Text(
                  context.translate('personal_expense_no_splits'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return SawaCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('splits_among_members'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapMD,
              const Divider(),
              AppSpacing.gapMD,
              for (int i = 0; i < splits.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (i + 1).toString(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      AppSpacing.gapMD,
                      Expanded(
                        child: Text(
                          memberNames[splits[i].memberId] ??
                              context.translate('member'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${(splits[i].amount / 100).toStringAsFixed(2)} ${context.translate('currency_symbol')}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < splits.length - 1)
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => SawaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            AppSpacing.gapMD,
            Expanded(
              child: Text(
                '${context.translate('error_loading_splits')}: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
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
              context.translate('delete_expense'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          context.translate('delete_expense_warning'),
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
            text: context.translate('delete'),
            width: 100,
            type: SawaButtonType.secondary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final screenContext = context;
    ActionDebouncer.execute(() async {
      setState(() => _isDeleting = true);
      try {
        final repository = ref.read(expenseRepositoryProvider);
        await repository.deleteExpense(expenseId: widget.expenseId);

        final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
        if (hapticEnabled) {
          HapticFeedback.mediumImpact();
        }

        ref.invalidate(expensesProvider);

        if (!mounted || !screenContext.mounted) return;
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              context.translate('expense_deleted_success'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        screenContext.pop();
      } catch (e) {
        if (!mounted || !screenContext.mounted) return;
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(context.translate('error_deleting_expense', arguments: {'error': ErrorFormatter.format(e, context)})),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    });
  }
}
