import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/expense_providers.dart';
import '../../domain/usecases/get_expense_summary.dart';

class ExpenseSummaryScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ExpenseSummaryScreen({
    super.key,
    required this.homeId,
  });

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

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final repository = ref.read(expenseRepositoryProvider);
    final summaryFuture = GetExpenseSummary(repository)(
      GetExpenseSummaryParams(
        homeId: widget.homeId,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'ملخص المصروفات' : 'Expense Summary', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'week', child: Text(isArabic ? 'هذا الأسبوع' : 'This Week')),
              PopupMenuItem(value: 'month', child: Text(isArabic ? 'هذا الشهر' : 'This Month')),
              PopupMenuItem(value: 'year', child: Text(isArabic ? 'هذا العام' : 'This Year')),
              PopupMenuItem(value: 'custom', child: Text(isArabic ? 'فترة مخصصة' : 'Custom Period')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<ExpenseSummary>(
        future: summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return BeityEmptyState(
              title: isArabic ? 'عذراً، حدث خطأ' : 'Oops, something went wrong',
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
              actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
              onActionPressed: () => setState(() {}),
            );
          }

          final summary = snapshot.data!;

          if (summary.expenseCount == 0) {
            return BeityEmptyState(
              title: isArabic ? 'لا توجد بيانات لهذه الفترة' : 'No data for this period',
              message: isArabic 
                  ? 'حاول تغيير الفترة الزمنية أو إضافة مصروفات جديدة' 
                  : 'Try changing the time period or adding new expenses',
              icon: Icons.analytics_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildTotalCard(summary, isArabic),
              AppSpacing.gapLG,
              _buildCategoryBreakdown(summary, isArabic),
              AppSpacing.gapLG,
              _buildMemberBreakdown(summary, isArabic),
              AppSpacing.gapXXL,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(ExpenseSummary summary, bool isArabic) {
    final theme = Theme.of(context);
    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            isArabic ? 'إجمالي المصروفات' : 'Total Expenses',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapMD,
          Text(
            '${(summary.totalAmount / 100).toStringAsFixed(2)} ${isArabic ? 'ر.س' : 'SAR'}',
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
                const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.primary),
                AppSpacing.gapXS,
                Text(
                  isArabic ? '${summary.expenseCount} مصروف' : '${summary.expenseCount} expenses',
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

  Widget _buildCategoryBreakdown(ExpenseSummary summary, bool isArabic) {
    if (summary.categoryBreakdown.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'حسب الفئة' : 'By Category',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapMD,
        BeityCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < summary.categoryBreakdown.length; i++) ...[
                _buildBreakdownRow(
                  icon: Icons.category_rounded,
                  label: summary.categoryBreakdown.keys.elementAt(i),
                  amount: summary.categoryBreakdown.values.elementAt(i),
                  percentage: summary.categoryPercentages[summary.categoryBreakdown.keys.elementAt(i)],
                  isArabic: isArabic,
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

  Widget _buildMemberBreakdown(ExpenseSummary summary, bool isArabic) {
    if (summary.memberBreakdown.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'حسب العضو' : 'By Member',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapMD,
        BeityCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < summary.memberBreakdown.length; i++) ...[
                _buildBreakdownRow(
                  icon: Icons.person_rounded,
                  label: summary.memberBreakdown.keys.elementAt(i),
                  amount: summary.memberBreakdown.values.elementAt(i),
                  isArabic: isArabic,
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
    required bool isArabic,
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
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (percentage != null) ...[
                  AppSpacing.gapXS,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                '${(amount / 100).toStringAsFixed(2)} ${isArabic ? 'ر.س' : 'SAR'}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
