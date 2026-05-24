import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../providers/expense_providers.dart';
import '../../../../core/utils/action_debouncer.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String homeId;

  const AddExpenseScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedShoppingItemId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(isArabic ? 'يجب تسجيل الدخول أولاً' : 'Must login first'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text) * 100; // Convert to cents
      final description = _descriptionController.text.trim();

      final repository = ref.read(expenseRepositoryProvider);
      await repository.createExpense(
        homeId: widget.homeId,
        amount: amount.round(),
        description: description,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        paidBy: user.id,
        shoppingListItemId: _selectedShoppingItemId,
        convertedAmount: amount.round(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(isArabic ? 'تم حفظ المصروف بنجاح' : 'Expense saved successfully'),
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
            content: Text(isArabic ? 'خطأ: $e' : 'Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إضافة مصروف' : 'Add Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            BeityCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'تفاصيل المصروف' : 'Expense Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _amountController,
                    labelText: isArabic ? 'المبلغ' : 'Amount',
                    hintText: '0.00',
                    prefixIcon: Icons.payments_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isArabic ? 'الرجاء إدخال المبلغ' : 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return isArabic ? 'الرجاء إدخال رقم صحيح' : 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return isArabic ? 'يجب أن يكون المبلغ أكبر من صفر' : 'Amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _descriptionController,
                    labelText: isArabic ? 'الوصف' : 'Description',
                    hintText: isArabic ? 'ماذا اشتريت؟' : 'What did you buy?',
                    prefixIcon: Icons.description_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isArabic ? 'الرجاء إدخال الوصف' : 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,
                  const Divider(),
                  AppSpacing.gapLG,
                  Text(
                    isArabic ? 'التاريخ' : 'Date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapSM,
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 20, color: theme.colorScheme.primary),
                          AppSpacing.gapMD,
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Icons.edit_calendar_rounded, size: 20, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,
            BeityButton(
              text: isArabic ? 'حفظ المصروف' : 'Save Expense',
              onPressed: () => ActionDebouncer.execute(_submit),
              isLoading: _isLoading,
              icon: Icons.check_rounded,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
