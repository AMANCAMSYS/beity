import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_card.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../onboarding/presentation/providers/app_tour_controller.dart';
import '../../../onboarding/presentation/providers/app_tour_target_registry.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ExpenseListScreen({super.key, required this.homeId});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appTourControllerProvider.notifier).maybeStartExpensesTour(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider(widget.homeId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              context.translate('expenses'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapSM,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                context.translate('beta'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: AppTourTargetRegistry.expensesSummaryKey,
            icon: const Icon(Icons.pie_chart_rounded),
            tooltip: context.translate('expense_summary'),
            onPressed: () => ActionDebouncer.execute(
              () => context.push('/expenses/summary', extra: widget.homeId),
            ),
          ),
          IconButton(
            key: AppTourTargetRegistry.expensesBalancesKey,
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: context.translate('balances'),
            onPressed: () => ActionDebouncer.execute(
              () => context.push('/expenses/balances', extra: widget.homeId),
            ),
          ),
          IconButton(
            key: AppTourTargetRegistry.expensesFilterKey,
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => ActionDebouncer.execute(_showFilterDialog),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: expensesAsync.when(
            data: (expenses) {
              var filteredExpenses = expenses;

              if (_startDate != null) {
                filteredExpenses = filteredExpenses
                    .where((e) => e.date.isAfter(_startDate!))
                    .toList();
              }
              if (_endDate != null) {
                filteredExpenses = filteredExpenses
                    .where(
                      (e) => e.date.isBefore(
                        _endDate!.add(const Duration(days: 1)),
                      ),
                    )
                    .toList();
              }
              if (_selectedCategoryId != null) {
                filteredExpenses = filteredExpenses
                    .where((e) => e.categoryId == _selectedCategoryId)
                    .toList();
              }
              if (_selectedMemberId != null) {
                filteredExpenses = filteredExpenses
                    .where((e) => e.paidBy == _selectedMemberId)
                    .toList();
              }

              if (filteredExpenses.isEmpty) {
                return BeityEmptyState(
                  title: expenses.isEmpty
                      ? context.translate('no_expenses_yet')
                      : context.translate('no_search_results'),
                  message: expenses.isEmpty
                      ? context.translate('expenses_empty_desc')
                      : context.translate('expenses_filter_empty_desc'),
                  icon: Icons.receipt_long_rounded,
                  actionText: expenses.isEmpty
                      ? context.translate('add_first_expense')
                      : context.translate('clear_filters_action'),
                  onAction: expenses.isEmpty
                      ? () => ActionDebouncer.execute(
                          () => context.push(
                            '/expenses/add',
                            extra: widget.homeId,
                          ),
                        )
                      : () => setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedCategoryId = null;
                          _selectedMemberId = null;
                        }),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(expensesProvider(widget.homeId)),
                child: ListView.builder(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg + MediaQuery.of(context).padding.bottom + 80,
                  ),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ExpenseCard(
                        expense: expense,
                        onTap: () => context.push('/expenses/${expense.id}'),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
            error: (error, stack) => BeityEmptyState(
              title: context.translate('error_title'),
              message: error.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
              actionText: context.translate('retry'),
              onAction: () => ref.invalidate(expensesProvider(widget.homeId)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: AppTourTargetRegistry.expensesAddKey,
        onPressed: () => ActionDebouncer.execute(
          () => context.push('/expenses/add', extra: widget.homeId),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.translate('add_expense')),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                AppSpacing.gapLG,
                Row(
                  children: [
                    Text(
                      context.translate('filter_expenses'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: theme
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapXL,
                _buildFilterTile(
                  title: context.translate('from_date'),
                  value: _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : context.translate('not_set'),
                  onClear: _startDate != null
                      ? () => setDialogState(() => _startDate = null)
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => _startDate = picked);
                    }
                  },
                ),
                AppSpacing.gapMD,
                _buildFilterTile(
                  title: context.translate('to_date'),
                  value: _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : context.translate('not_set'),
                  onClear: _endDate != null
                      ? () => setDialogState(() => _endDate = null)
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => _endDate = picked);
                    }
                  },
                ),
                AppSpacing.gapXXL,
                Row(
                  children: [
                    Expanded(
                      child: BeityButton(
                        type: BeityButtonType.secondary,
                        text: context.translate('clear_all'),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    AppSpacing.gapMD,
                    Expanded(
                      child: BeityButton(
                        text: context.translate('apply'),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTile({
    required String title,
    required String value,
    VoidCallback? onClear,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return BeityCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.gapLG,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapXS,
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClear,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withValues(
                    alpha: 0.1,
                  ),
                  iconSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
