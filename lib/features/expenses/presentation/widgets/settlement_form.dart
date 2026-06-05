import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import '../providers/balance_providers.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sawa/core/errors/error_formatter.dart';
import 'package:sawa/core/utils/arabic_number_parser.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';

class SettlementForm extends ConsumerStatefulWidget {
  final String homeId;
  final String fromMember;
  final String toMember;
  final int maxAmount;
  final VoidCallback? onSuccess;

  const SettlementForm({
    super.key,
    required this.homeId,
    required this.fromMember,
    required this.toMember,
    required this.maxAmount,
    this.onSuccess,
  });

  @override
  ConsumerState<SettlementForm> createState() => _SettlementFormState();
}

class _SettlementFormState extends ConsumerState<SettlementForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.maxAmount / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
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

    ActionDebouncer.execute(() async {
      setState(() => _isLoading = true);
      try {
        final amount =
            _amountController.text.parseDouble() * 100; // Convert to cents

        final repository = ref.read(settlementRepositoryProvider);
        await repository.createSettlement(
          homeId: widget.homeId,
          fromMember: widget.fromMember,
          toMember: widget.toMember,
          amount: amount.round(),
          paymentMethod: _paymentMethod,
          date: _selectedDate,
        );

        // Invalidate balances to refresh
        ref.invalidate(balancesProvider(widget.homeId));
        ref.invalidate(settlementsProvider(widget.homeId));

        if (mounted) {
          final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
          if (hapticEnabled) {
            HapticFeedback.mediumImpact();
          }
          widget.onSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(context.translate('settlement_recorded_success')),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                '${context.translate('error', fallback: 'Error')}: ${ErrorFormatter.format(e, context)}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SawaCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                SawaTextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  labelText: context.translate('amount', fallback: 'Amount'),
                  hintText: '0.00',
                  suffixIcon: const Icon(Icons.currency_exchange_rounded),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.translate(
                        'please_enter_amount',
                        fallback: 'Please enter amount',
                      );
                    }
                    final amount = value.tryParseDouble();
                    if (amount == null || amount <= 0) {
                      return context.translate(
                        'please_enter_valid_amount',
                        fallback: 'Please enter a valid amount',
                      );
                    }
                    if (amount * 100 > widget.maxAmount) {
                      return context.translate(
                        'amount_exceeds_balance',
                        fallback: 'Amount exceeds remaining balance',
                      );
                    }
                    return null;
                  },
                ),
                AppSpacing.gapLG,

                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: context.translate('payment_method', fallback: 'Payment Method'),
                    prefixIcon: const Icon(Icons.payments_rounded),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text(context.translate('cash', fallback: 'Cash')),
                    ),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text(context.translate('bank_transfer', fallback: 'Bank Transfer')),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(context.translate('other', fallback: 'Other')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
                ),
                AppSpacing.gapLG,

                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        AppSpacing.gapMD,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('date', fallback: 'Date'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateFormat.format(_selectedDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapXL,

          SawaButton(
            text: context.translate('record_payment', fallback: 'Record Payment'),
            onPressed: _submit,
            isLoading: _isLoading,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}
