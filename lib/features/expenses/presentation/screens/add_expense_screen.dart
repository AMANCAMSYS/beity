import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../../homes/data/models/home_member_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../domain/usecases/split_expense.dart';
import '../providers/expense_providers.dart';
import '../widgets/split_selector.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import 'package:beity/core/errors/error_formatter.dart';
import 'package:beity/core/utils/arabic_number_parser.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String homeId;

  const AddExpenseScreen({super.key, required this.homeId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedShoppingItemId;
  String? _paidBy;
  bool _splitBetweenMembers = true;
  List<({String memberId, int amount})> _splits = const [];
  bool _isLoading = false;

  // Step wizard state
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _paidBy = SupabaseService.client.auth.currentUser?.id;
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  int get _amountCents {
    final value = _amountController.text.trim().tryParseDouble();
    if (value == null) return 0;
    return (value * 100).round();
  }

  String _memberDisplayName(HomeMemberModel member) {
    final name = member.userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = member.userEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return context.translate('member');
  }

  List<HomeMemberModel> _activeMembers(List<HomeMemberModel> members) {
    return members
        .where(
          (member) => member.status == 'active' && member.deletedAt == null,
        )
        .toList();
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
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

    final user = SupabaseService.client.auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              context.translate('must_login_first'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = _amountCents;
      final description = _descriptionController.text.trim();
      final activeMembers = _activeMembers(
        ref.read(homeMembersProvider(widget.homeId)).valueOrNull ?? [],
      );
      final paidBy = _paidBy ?? user.id;
      final shouldCreateSplits =
          _splitBetweenMembers && activeMembers.length > 1;
      final splits = shouldCreateSplits
          ? _splits
          : const <({String memberId, int amount})>[];

      if (!activeMembers.any((member) => member.userId == paidBy)) {
        throw Exception(
          context.translate('select_active_payer'),
        );
      }

      if (shouldCreateSplits) {
        if (splits.length <= 1) {
          throw Exception(
            context.translate('select_at_least_two_members'),
          );
        }
        if (!SplitExpense.validateSplits(totalAmount: amount, splits: splits)) {
          throw Exception(
            context.translate('split_total_must_match'),
          );
        }
      }

      final activeHome = ref.read(cachedActiveHomeProvider);
      final defaultCurrency = activeHome?.defaultCurrency ?? 'SAR';

      final repository = ref.read(expenseRepositoryProvider);
      await repository.createExpenseWithSplits(
        homeId: widget.homeId,
        amount: amount,
        description: description,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        paidBy: paidBy,
        shoppingListItemId: _selectedShoppingItemId,
        convertedAmount: amount,
        currencyCode: defaultCurrency,
        splits: splits,
      );

      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (hapticEnabled) {
        HapticFeedback.mediumImpact();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              context.translate('expense_saved_success'),
            ),
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
            content: Text('${context.translate('error')}: ${ErrorFormatter.format(e, context)}'),
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
    final theme = Theme.of(context);
    final membersAsync = ref.watch(homeMembersProvider(widget.homeId));

    final activeHome = ref.watch(cachedActiveHomeProvider);
    final defaultCurrency = activeHome?.defaultCurrency ?? 'SAR';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate('add_expense'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${context.translate('step')} ${_currentStep + 1} ${context.translate('of')} 3',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Linear Progress indicator for step progress
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3.0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_currentStep == 0) ...[
                    _buildStep0(context, theme, defaultCurrency),
                  ] else if (_currentStep == 1) ...[
                    _buildStep1(context, membersAsync, theme),
                  ] else if (_currentStep == 2) ...[
                    _buildStep2(context, membersAsync, theme),
                  ],
                  AppSpacing.gapXXL,
                  _buildNavigationButtons(context, membersAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0(BuildContext context, ThemeData theme, String defaultCurrency) {
    return BeityCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payments_rounded, color: theme.colorScheme.primary),
              ),
              AppSpacing.gapMD,
              Text(
                context.translate('expense_details'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.gapLG,
          BeityTextField(
            controller: _amountController,
            focusNode: _amountFocusNode,
            textInputAction: TextInputAction.next,
            labelText: context.translate('amount'),
            hintText: '0.00',
            prefixIcon: Icons.payments_rounded,
            suffixText: defaultCurrency,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_descriptionFocusNode);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.translate('please_enter_amount');
              }
              final parsed = value.tryParseDouble();
              if (parsed == null) {
                return context.translate('please_enter_valid_number');
              }
              if (parsed <= 0) {
                return context.translate('amount_greater_than_zero');
              }
              return null;
            },
          ),
          AppSpacing.gapLG,
          BeityTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            textInputAction: TextInputAction.done,
            labelText: context.translate('description'),
            hintText: context.translate('what_did_you_buy'),
            prefixIcon: Icons.description_rounded,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.translate('please_enter_description');
              }
              return null;
            },
          ),
          AppSpacing.gapLG,
          const Divider(),
          AppSpacing.gapLG,
          Text(
            context.translate('date'),
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
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  AppSpacing.radiusMd,
                ),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacing.gapMD,
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(
    BuildContext context,
    AsyncValue<List<HomeMemberModel>> membersAsync,
    ThemeData theme,
  ) {
    return membersAsync.when(
      data: (members) {
        final activeMembers = _activeMembers(members);
        if (activeMembers.isEmpty) {
          return BeityCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              context.translate('no_active_members_home'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final effectivePaidBy =
            activeMembers.any((member) => member.userId == _paidBy)
            ? _paidBy!
            : activeMembers.first.userId;

        if (_paidBy != effectivePaidBy) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _paidBy = effectivePaidBy;
              _splits = const [];
            });
          });
        }

        return BeityCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                  ),
                  AppSpacing.gapMD,
                  Text(
                    context.translate('paid_by'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLG,
              Text(
                context.translate('paid_by_instructions'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapLG,
              DropdownButtonFormField<String>(
                initialValue: effectivePaidBy,
                decoration: InputDecoration(
                  labelText: context.translate('paid_by'),
                  prefixIcon: const Icon(Icons.account_circle_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                items: [
                  for (final member in activeMembers)
                    DropdownMenuItem(
                      value: member.userId,
                      child: Text(_memberDisplayName(member)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _paidBy = value;
                    _splits = const [];
                  });
                },
              ),
            ],
          ),
        );
      },
      loading: () => const BeityCard(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => BeityCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          error.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(
    BuildContext context,
    AsyncValue<List<HomeMemberModel>> membersAsync,
    ThemeData theme,
  ) {
    return membersAsync.when(
      data: (members) {
        final activeMembers = _activeMembers(members);
        if (activeMembers.isEmpty) return const SizedBox.shrink();

        final effectivePaidBy =
            activeMembers.any((member) => member.userId == _paidBy)
            ? _paidBy!
            : activeMembers.first.userId;

        final amount = _amountCents;
        final memberIds = activeMembers.map((member) => member.userId).toList();
        final memberNames = activeMembers
            .map((member) => _memberDisplayName(member))
            .toList();
        final canSplit = activeMembers.length > 1 && amount > 0;

        return BeityCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.pie_chart_rounded, color: theme.colorScheme.primary),
                  ),
                  AppSpacing.gapMD,
                  Text(
                    context.translate('payment_split'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLG,
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _splitBetweenMembers && activeMembers.length > 1,
                onChanged: activeMembers.length > 1
                    ? (value) {
                        setState(() {
                          _splitBetweenMembers = value;
                          if (!value) _splits = const [];
                        });
                      }
                    : null,
                title: Text(
                  context.translate('split_with_members'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  activeMembers.length <= 1
                      ? context.translate('personal_expense_one_member')
                      : context.translate('split_update_balances'),
                ),
              ),
              if (_splitBetweenMembers && activeMembers.length > 1) ...[
                AppSpacing.gapLG,
                if (amount <= 0)
                  Text(
                    context.translate('enter_amount_first_split'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  SplitSelector(
                    key: ValueKey(
                      '${amount}_${effectivePaidBy}_${memberIds.join(',')}',
                    ),
                    totalAmount: amount,
                    memberIds: memberIds,
                    payerId: effectivePaidBy,
                    memberNames: memberNames,
                    onChanged: (splits) => _splits = splits,
                  ),
              ],
              if (!canSplit && activeMembers.length > 1) ...[
                AppSpacing.gapMD,
                Text(
                  context.translate('personal_expense_until_valid_amount'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    AsyncValue<List<HomeMemberModel>> membersAsync,
  ) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: BeityButton(
              text: context.translate('back'),
              type: BeityButtonType.secondary,
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              icon: Icons.arrow_back_rounded,
            ),
          ),
          AppSpacing.gapMD,
        ],
        Expanded(
          child: BeityButton(
            text: _currentStep < 2
                ? context.translate('next')
                : context.translate('add_expense'),
            onPressed: () {
              if (_currentStep < 2) {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _currentStep++;
                  });
                }
              } else {
                ActionDebouncer.execute(_submit);
              }
            },
            isLoading: _isLoading,
            icon: _currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
          ),
        ),
      ],
    );
  }
}
