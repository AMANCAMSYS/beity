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

class ExpenseListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ExpenseListScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider(widget.homeId));
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              isArabic ? 'المصروفات' : 'Expenses',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapSM,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                isArabic ? 'تجريبي' : 'Beta',
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
            icon: const Icon(Icons.pie_chart_rounded),
            tooltip: isArabic ? 'ملخص المصروفات' : 'Expense Summary',
            onPressed: () => ActionDebouncer.execute(() => context.push('/expenses/summary', extra: widget.homeId)),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: isArabic ? 'الأرصدة' : 'Balances',
            onPressed: () => ActionDebouncer.execute(() => context.push('/expenses/balances', extra: widget.homeId)),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => ActionDebouncer.execute(_showFilterDialog),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          var filteredExpenses = expenses;

          if (_startDate != null) {
            filteredExpenses = filteredExpenses
                .where((e) => e.date.isAfter(_startDate!))
                .toList();
          }
          if (_endDate != null) {
            filteredExpenses = filteredExpenses
                .where((e) => e.date.isBefore(_endDate!.add(const Duration(days: 1))))
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
                  ? (isArabic ? 'لا توجد مصروفات بعد' : 'No expenses yet')
                  : (isArabic ? 'لا توجد نتائج بحث' : 'No search results'),
              message: expenses.isEmpty
                  ? (isArabic ? 'ابدأ بتتبع مصروفات منزلك وتوزيعها بين الأعضاء بكل سهولة' : 'Start tracking your home expenses and splitting them easily')
                  : (isArabic ? 'جرب تغيير خيارات التصفية أو مسحها للوصول لما تبحث عنه' : 'Try changing or clearing filters to find what you are looking for'),
              icon: Icons.receipt_long_rounded,
              actionText: expenses.isEmpty
                  ? (isArabic ? 'إضافة أول مصروف' : 'Add First Expense')
                  : (isArabic ? 'مسح التصفية' : 'Clear Filters'),
              onActionPressed: expenses.isEmpty
                  ? () => ActionDebouncer.execute(() => context.push('/expenses/add', extra: widget.homeId))
                  : () => setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedCategoryId = null;
                        _selectedMemberId = null;
                      }),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => BeityEmptyState(
          title: isArabic ? 'عذراً، حدث خطأ' : 'Oops, something went wrong',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
          onActionPressed: () => ref.invalidate(expensesProvider(widget.homeId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ActionDebouncer.execute(() => context.push('/expenses/add', extra: widget.homeId)),
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'إضافة مصروف' : 'Add Expense'),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: EdgeInsets.fromLTRB(
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
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                AppSpacing.gapLG,
                Row(
                  children: [
                    Text(
                      isArabic ? 'تصفية المصروفات' : 'Filter Expenses',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapXL,
                _buildFilterTile(
                  title: isArabic ? 'من تاريخ' : 'From Date',
                  value: _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : (isArabic ? 'غير محدد' : 'Not set'),
                  onClear: _startDate != null ? () => setDialogState(() => _startDate = null) : null,
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
                  title: isArabic ? 'إلى تاريخ' : 'To Date',
                  value: _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : (isArabic ? 'غير محدد' : 'Not set'),
                  onClear: _endDate != null ? () => setDialogState(() => _endDate = null) : null,
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
                        text: isArabic ? 'مسح الفلاتر' : 'Clear All',
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
                        text: isArabic ? 'تطبيق' : 'Apply',
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
              child: Icon(Icons.calendar_today_rounded, size: 20, color: theme.colorScheme.primary),
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
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClear,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                  iconSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
