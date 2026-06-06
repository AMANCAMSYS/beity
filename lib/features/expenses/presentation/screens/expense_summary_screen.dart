import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_loading_state.dart';
import 'package:sawa/core/services/sync_coordinator.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../homes/data/models/home_member_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/expense_providers.dart';
import '../../domain/usecases/get_expense_summary.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/error_formatter.dart';

class ExpenseSummaryScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ExpenseSummaryScreen({super.key, required this.homeId});

  @override
  ConsumerState<ExpenseSummaryScreen> createState() =>
      _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends ConsumerState<ExpenseSummaryScreen> {
  String _selectedPeriod = 'month';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();

    // Trigger silent background prefetch/sync to ensure cache is populated with members, categories, and expenses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(syncCoordinatorProvider.notifier)
            .syncAll(widget.homeId, force: false);
      }
    });
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'custom':
        // Keep existing dates
        break;
    }
  }

  Widget _buildSyncIndicator(WidgetRef ref, ThemeData theme) {
    final syncState = ref.watch(syncCoordinatorProvider);
    if (syncState.status == SyncStatus.idle ||
        syncState.status == SyncStatus.success) {
      return const SizedBox.shrink();
    }

    Color color = theme.colorScheme.primary;
    String text = context.translate('syncing');
    IconData icon = Icons.sync_rounded;

    if (syncState.status == SyncStatus.partiallySynced) {
      color = Colors.orange;
      text = context.translate('partially_synced');
      icon = Icons.warning_amber_rounded;
    } else if (syncState.status == SyncStatus.error) {
      color = Colors.red;
      text = context.translate('sync_error');
      icon = Icons.cloud_off_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: AppSpacing.md,
      ),
      color: color.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider(widget.homeId));
    final membersAsync = ref.watch(homeMembersProvider(widget.homeId));
    final categoryNames = categoriesAsync.when(
      data: (categories) => {
        for (final category in categories)
          category.id: category.name == 'Other'
              ? context.translate('other')
              : category.name,
      },
      loading: () => const <String, String>{},
      error: (error, stackTrace) => const <String, String>{},
    );
    final memberNames = membersAsync.when(
      data: (members) => _memberNames(members),
      loading: () => const <String, String>{},
      error: (error, stackTrace) => const <String, String>{},
    );

    final summaryAsync = ref.watch(
      expenseSummaryProvider((
        homeId: widget.homeId,
        startDate: _startDate,
        endDate: _endDate,
      )),
    );

    final initialSyncCompletedAsync = ref.watch(
      initialSyncCompletedExpensesProvider(widget.homeId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.translate('expense_summary'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.translate('refresh'),
            onPressed: () => ref
                .read(syncCoordinatorProvider.notifier)
                .syncAll(
                  widget.homeId,
                  force: true,
                  targetDomain: 'expenses',
                  repairMissing: true,
                ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Text(context.translate('this_week')),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text(context.translate('this_month')),
              ),
              PopupMenuItem(
                value: 'year',
                child: Text(context.translate('this_year')),
              ),
              PopupMenuItem(
                value: 'custom',
                child: Text(context.translate('custom_period')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncIndicator(ref, Theme.of(context)),
          Expanded(
            child: summaryAsync.when(
              data: (summary) {
                if (summary.expenseCount == 0) {
                  final isSyncCompleted =
                      initialSyncCompletedAsync.value ?? false;
                  if (!isSyncCompleted) {
                    return SawaLoadingState(
                      message: context.translate('loading_expense_summary'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(syncCoordinatorProvider.notifier)
                        .syncAll(
                          widget.homeId,
                          force: true,
                          targetDomain: 'expenses',
                          repairMissing: true,
                        ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: SawaEmptyState(
                          title: context.translate('no_data_for_period'),
                          message: context.translate('no_data_for_period_desc'),
                          icon: Icons.analytics_rounded,
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(syncCoordinatorProvider.notifier)
                      .syncAll(
                        widget.homeId,
                        force: true,
                        targetDomain: 'expenses',
                        repairMissing: true,
                      ),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildTotalCard(summary),
                      AppSpacing.gapLG,
                      _buildCategoryBreakdown(summary, categoryNames),
                      AppSpacing.gapLG,
                      _buildMemberBreakdown(summary, memberNames),
                      AppSpacing.gapXXL,
                    ],
                  ),
                );
              },
              loading: () {
                final isSyncCompleted =
                    initialSyncCompletedAsync.value ?? false;
                if (!isSyncCompleted) {
                  return SawaLoadingState(
                    message: context.translate('loading_expense_summary'),
                  );
                }
                return SawaLoadingState(
                  message: context.translate('loading_expense_summary'),
                );
              },
              error: (error, stackTrace) => SawaEmptyState(
                title: context.translate('error_title'),
                message: ErrorFormatter.format(error, context),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
                onAction: () => ref
                    .read(syncCoordinatorProvider.notifier)
                    .syncAll(
                      widget.homeId,
                      force: true,
                      targetDomain: 'expenses',
                      repairMissing: true,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ExpenseSummary summary) {
    final theme = Theme.of(context);
    return SawaCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            context.translate('total_expenses'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapMD,
          Text(
            '${(summary.totalAmount / 100).toStringAsFixed(2)} ${context.translate('currency_symbol')}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          AppSpacing.gapMD,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                AppSpacing.gapXS,
                Text(
                  context.translate(
                    'expenses_count_label',
                    arguments: {'count': summary.expenseCount.toString()},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _memberNames(List<HomeMemberModel> members) {
    final names = <String, String>{};
    for (final member in members) {
      final displayName = (member.userName?.trim().isNotEmpty ?? false)
          ? member.userName!.trim()
          : ((member.userEmail?.trim().isNotEmpty ?? false)
                ? member.userEmail!.trim()
                : context.translate('member'));
      names[member.userId] = displayName;
      names[member.id] = displayName;
    }
    return names;
  }

  String _categoryLabel(String categoryId, Map<String, String> categoryNames) {
    if (categoryId == 'uncategorized' || categoryId.isEmpty) {
      return context.translate('uncategorized');
    }
    return categoryNames[categoryId] ?? context.translate('unknown_category');
  }

  String _memberLabel(String memberId, Map<String, String> memberNames) {
    return memberNames[memberId] ?? context.translate('unknown_member');
  }

  Widget _buildCategoryBreakdown(
    ExpenseSummary summary,
    Map<String, String> categoryNames,
  ) {
    if (summary.categoryBreakdown.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('by_category'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapMD,
        SawaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < summary.categoryBreakdown.length; i++) ...[
                _buildBreakdownRow(
                  icon: Icons.category_rounded,
                  label: _categoryLabel(
                    summary.categoryBreakdown.keys.elementAt(i),
                    categoryNames,
                  ),
                  amount: summary.categoryBreakdown.values.elementAt(i),
                  percentage:
                      summary.categoryPercentages[summary.categoryBreakdown.keys
                          .elementAt(i)],
                  theme: theme,
                ),
                if (i < summary.categoryBreakdown.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberBreakdown(
    ExpenseSummary summary,
    Map<String, String> memberNames,
  ) {
    if (summary.memberBreakdown.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('by_member_label'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapMD,
        SawaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < summary.memberBreakdown.length; i++) ...[
                _buildBreakdownRow(
                  icon: Icons.person_rounded,
                  label: _memberLabel(
                    summary.memberBreakdown.keys.elementAt(i),
                    memberNames,
                  ),
                  amount: summary.memberBreakdown.values.elementAt(i),
                  theme: theme,
                ),
                if (i < summary.memberBreakdown.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required String label,
    required int amount,
    double? percentage,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          AppSpacing.gapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (percentage != null) ...[
                  AppSpacing.gapXS,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapLG,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(amount / 100).toStringAsFixed(2)} ${context.translate('currency_symbol')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (percentage != null)
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
