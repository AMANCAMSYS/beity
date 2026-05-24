import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/expense_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../../../../core/utils/action_debouncer.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل المصروف' : 'Expense Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(isArabic ? 'ميزة تعديل المصروف ستتوفر قريباً' : 'Edit feature coming soon'),
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
            onPressed: _isDeleting ? null : () => _confirmDelete(context, isArabic),
          ),
        ],
      ),
      body: expenseAsync.when(
        data: (expense) {
          if (expense == null) {
            return BeityEmptyState(
              title: isArabic ? 'المصروف غير موجود' : 'Expense not found',
              message: isArabic 
                  ? 'عذراً، لا يمكن العثور على تفاصيل هذا المصروف حالياً' 
                  : 'Sorry, we couldn\'t find the details for this expense at the moment',
              icon: Icons.receipt_long_rounded,
              actionText: isArabic ? 'العودة' : 'Go Back',
              onAction: () => context.pop(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildExpenseHeader(context, expense, isArabic, theme),
              AppSpacing.gapLG,
              _buildSplitsSection(context, splitsAsync, isArabic, theme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => BeityEmptyState(
          title: isArabic ? 'عذراً، حدث خطأ' : 'Sorry, an error occurred',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Retry',
          onAction: () => ref.invalidate(expenseByIdProvider(widget.expenseId)),
        ),
      ),
    );
  }

  Widget _buildExpenseHeader(BuildContext context, Expense expense, bool isArabic, ThemeData theme) {
    return BeityCard(
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
                      '${(expense.convertedAmount / 100).toStringAsFixed(2)} ${isArabic ? 'ر.س' : 'SAR'}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: expense.isCancelled ? theme.colorScheme.outline : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (expense.isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_rounded, size: 14, color: theme.colorScheme.error),
                      AppSpacing.gapXXS,
                      Text(
                        isArabic ? 'ملغي' : 'Cancelled',
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
            isArabic ? 'التاريخ' : 'Date',
            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            theme,
          ),
          _buildDetailRow(
            Icons.info_outline_rounded,
            isArabic ? 'الحالة' : 'Status',
            expense.isCancelled ? (isArabic ? 'ملغي' : 'Cancelled') : (isArabic ? 'نشط' : 'Active'),
            theme,
            color: expense.isCancelled ? theme.colorScheme.error : AppColors.success,
          ),
          if (expense.categoryId != null)
            _buildDetailRow(
              Icons.category_rounded,
              isArabic ? 'الفئة' : 'Category',
              isArabic ? 'تصنيف' : 'Category',
              theme,
            ),
          if (expense.currencyCode != 'SAR')
            _buildDetailRow(
              Icons.currency_exchange_rounded,
              isArabic ? 'العملة الأصلية' : 'Original Currency',
              expense.currencyCode,
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme, {Color? color}) {
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
      BuildContext context, AsyncValue<List<ExpenseSplit>> splitsAsync, bool isArabic, ThemeData theme) {
    return splitsAsync.when(
      data: (splits) {
        if (splits.isEmpty) {
          return BeityCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                ),
                AppSpacing.gapMD,
                Text(
                  isArabic ? 'مصروف شخصي - لا يوجد تقسيم' : 'Personal expense - No splits',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return BeityCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'التقسيم بين الأعضاء' : 'Splits among members',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          (i + 1).toString(),
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      AppSpacing.gapMD,
                      Expanded(
                        child: Text(
                          isArabic ? 'عضو العائلة' : 'Family Member',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${(splits[i].amount / 100).toStringAsFixed(2)} ${isArabic ? 'ر.س' : 'SAR'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < splits.length - 1)
                  Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => BeityCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            AppSpacing.gapMD,
            Expanded(
              child: Text(
                '${isArabic ? 'خطأ في تحميل التقسيم' : 'Error loading splits'}: $error',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, bool isArabic) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            AppSpacing.gapMD,
            Text(isArabic ? 'حذف المصروف' : 'Delete Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            isArabic 
                ? 'هل أنت متأكد من حذف هذا المصروف؟ سيتم الاحتفاظ بالسجل لأغراض التدقيق.' 
                : 'Are you sure you want to delete this expense? The record will be kept for auditing purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              isArabic ? 'إلغاء' : 'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ),
          BeityButton(
            text: isArabic ? 'حذف' : 'Delete',
            width: 100,
            type: BeityButtonType.secondary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ActionDebouncer.execute(() async {
        setState(() => _isDeleting = true);
        try {
          final repository = ref.read(expenseRepositoryProvider);
          await repository.deleteExpense(expenseId: widget.expenseId);

          ref.invalidate(expensesProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(isArabic ? 'تم حذف المصروف بنجاح' : 'Expense deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(isArabic ? 'خطأ في الحذف: $e' : 'Error deleting: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isDeleting = false);
          }
        }
      });
    }
  }
}
