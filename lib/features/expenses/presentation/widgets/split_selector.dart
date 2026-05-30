import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SplitType { equally, percentage, shares, custom }

class SplitSelector extends StatefulWidget {
  final int totalAmount; // cents
  final List<String> memberIds;
  final String payerId;
  final List<String> memberNames;
  final void Function(List<({String memberId, int amount})> splits) onChanged;

  const SplitSelector({
    super.key,
    required this.totalAmount,
    required this.memberIds,
    required this.payerId,
    required this.memberNames,
    required this.onChanged,
  });

  @override
  State<SplitSelector> createState() => _SplitSelectorState();
}

class _SplitSelectorState extends State<SplitSelector> {
  SplitType _splitType = SplitType.equally;
  
  // Equal Split toggles
  Set<String> _selectedMembers = {};

  // Custom Amount fields
  final Map<String, int> _customAmounts = {};
  final Map<String, TextEditingController> _amountControllers = {};

  // Percentage fields
  final Map<String, double> _percentages = {};
  final Map<String, TextEditingController> _percentageControllers = {};

  // Shares fields
  final Map<String, double> _shares = {};
  final Map<String, TextEditingController> _sharesControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedMembers = Set.from(widget.memberIds);
    
    for (var id in widget.memberIds) {
      _amountControllers[id] = TextEditingController();
      _percentageControllers[id] = TextEditingController();
      _sharesControllers[id] = TextEditingController();
      
      // Default calculations: Equal distribution percentages
      final defaultPct = 100.0 / widget.memberIds.length;
      _percentages[id] = defaultPct;
      _percentageControllers[id]!.text = defaultPct.toStringAsFixed(1);
      
      // Default shares = 1 share per member
      _shares[id] = 1.0;
      _sharesControllers[id]!.text = '1';
    }
    
    _updateSplits();
  }

  @override
  void didUpdateWidget(covariant SplitSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    final removedMembers = oldWidget.memberIds.where(
      (id) => !widget.memberIds.contains(id),
    );
    for (final id in removedMembers) {
      _amountControllers.remove(id)?.dispose();
      _percentageControllers.remove(id)?.dispose();
      _sharesControllers.remove(id)?.dispose();
      _customAmounts.remove(id);
      _percentages.remove(id);
      _shares.remove(id);
      _selectedMembers.remove(id);
    }

    for (final id in widget.memberIds) {
      _amountControllers.putIfAbsent(id, TextEditingController.new);
      _percentageControllers.putIfAbsent(id, TextEditingController.new);
      _sharesControllers.putIfAbsent(id, TextEditingController.new);
      _percentages.putIfAbsent(id, () => 100.0 / widget.memberIds.length);
      _shares.putIfAbsent(id, () => 1.0);
    }

    if (_selectedMembers.isEmpty) {
      _selectedMembers = Set.from(widget.memberIds);
    }

    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.payerId != widget.payerId ||
        oldWidget.memberIds.length != widget.memberIds.length) {
      _updateSplits();
    }
  }

  @override
  void dispose() {
    for (var ctrl in _amountControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _percentageControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _sharesControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _updateSplits() {
    List<({String memberId, int amount})> splits;

    switch (_splitType) {
      case SplitType.equally:
        splits = _calculateEqualSplits();
        break;
      case SplitType.custom:
        splits = _calculateCustomSplits();
        break;
      case SplitType.percentage:
        splits = _calculatePercentageSplits();
        break;
      case SplitType.shares:
        splits = _calculateSharesSplits();
        break;
    }

    widget.onChanged(splits);
  }

  List<({String memberId, int amount})> _calculateEqualSplits() {
    if (_selectedMembers.isEmpty) return [];

    final selected = widget.memberIds
        .where((id) => _selectedMembers.contains(id))
        .toList();
        
    final baseAmount = widget.totalAmount ~/ selected.length;
    final remainder = widget.totalAmount % selected.length;
    final remainderMember = selected.contains(widget.payerId)
        ? widget.payerId
        : selected.first;

    return selected.map((memberId) {
      final amount = memberId == remainderMember
          ? baseAmount + remainder
          : baseAmount;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  List<({String memberId, int amount})> _calculateCustomSplits() {
    return widget.memberIds.map((memberId) {
      final amount = _customAmounts[memberId] ?? 0;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  List<({String memberId, int amount})> _calculatePercentageSplits() {
    if (widget.memberIds.isEmpty) return [];

    final initialSplits = widget.memberIds.map((id) {
      final pct = _percentages[id] ?? 0.0;
      final amount = (widget.totalAmount * pct / 100.0).round();
      return (memberId: id, amount: amount);
    }).toList();

    // Verify if percentages sum up to 100% (allowing small double rounding gaps)
    final totalPct = _percentages.values.fold(0.0, (sum, val) => sum + val);
    final isSumMatched = (totalPct - 100.0).abs() < 0.01;

    if (isSumMatched) {
      final sumCents = initialSplits.fold(0, (sum, split) => sum + split.amount);
      final diff = widget.totalAmount - sumCents;
      if (diff != 0) {
        final adjustIndex = initialSplits.indexWhere((s) => s.memberId == widget.payerId);
        final targetIndex = adjustIndex != -1 ? adjustIndex : 0;
        initialSplits[targetIndex] = (
          memberId: initialSplits[targetIndex].memberId,
          amount: initialSplits[targetIndex].amount + diff,
        );
      }
    }

    return initialSplits;
  }

  List<({String memberId, int amount})> _calculateSharesSplits() {
    final totalShares = _shares.values.fold(0.0, (sum, val) => sum + val);
    if (totalShares <= 0) {
      return widget.memberIds.map((id) => (memberId: id, amount: 0)).toList();
    }

    final initialSplits = widget.memberIds.map((id) {
      final sh = _shares[id] ?? 0.0;
      final amount = (widget.totalAmount * sh / totalShares).round();
      return (memberId: id, amount: amount);
    }).toList();

    // Rounding remainder adjustments
    final sumCents = initialSplits.fold(0, (sum, split) => sum + split.amount);
    final diff = widget.totalAmount - sumCents;
    if (diff != 0) {
      final adjustIndex = initialSplits.indexWhere((s) => s.memberId == widget.payerId);
      final targetIndex = adjustIndex != -1 ? adjustIndex : 0;
      initialSplits[targetIndex] = (
        memberId: initialSplits[targetIndex].memberId,
        amount: initialSplits[targetIndex].amount + diff,
      );
    }

    return initialSplits;
  }

  @override
  Widget build(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final settingsLocale = container.read(appSettingsProvider).locale;
    final isArabic = settingsLocale.languageCode == 'ar';
    final currencySymbol = isArabic
        ? 'ر.س'
        : (settingsLocale.languageCode == 'tr' ? 'TL' : 'SAR');
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('split_method'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapSM,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SegmentedButton<SplitType>(
            segments: [
              ButtonSegment(
                value: SplitType.equally,
                icon: const Icon(Icons.balance_rounded, size: 16),
                label: Text(context.translate('equally')),
              ),
              ButtonSegment(
                value: SplitType.percentage,
                icon: const Icon(Icons.percent_rounded, size: 16),
                label: Text(context.translate('percentage')),
              ),
              ButtonSegment(
                value: SplitType.shares,
                icon: const Icon(Icons.pie_chart_rounded, size: 16),
                label: Text(context.translate('shares')),
              ),
              ButtonSegment(
                value: SplitType.custom,
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: Text(context.translate('custom')),
              ),
            ],
            selected: {_splitType},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
            onSelectionChanged: (selection) {
              setState(() {
                _splitType = selection.first;
                _updateSplits();
              });
            },
          ),
        ),
        AppSpacing.gapLG,
        Text(
          context.translate('splitting_shares'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapSM,
        
        // ── Render correct sharing layout based on strategy ──
        switch (_splitType) {
          SplitType.equally => _buildEqualSplitView(currencySymbol, theme),
          SplitType.custom => _buildCustomSplitView(currencySymbol, theme),
          SplitType.percentage => _buildPercentageSplitView(currencySymbol, theme),
          SplitType.shares => _buildSharesSplitView(currencySymbol, theme),
        },

        // ── Render bottom status validator alerts ──
        AppSpacing.gapLG,
        _buildBottomValidator(currencySymbol, theme),
      ],
    );
  }

  Widget _buildEqualSplitView(String currencySymbol, ThemeData theme) {
    final splitAmounts = {
      for (final split in _calculateEqualSplits()) split.memberId: split.amount,
    };

    return BeityCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < widget.memberIds.length; i++) ...[
            CheckboxListTile(
              title: Text(
                widget.memberNames[i],
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: _selectedMembers.contains(widget.memberIds[i])
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: _selectedMembers.contains(widget.memberIds[i])
                  ? Text(
                      '${((splitAmounts[widget.memberIds[i]] ?? 0) / 100).toStringAsFixed(2)} $currencySymbol',
                    )
                  : null,
              value: _selectedMembers.contains(widget.memberIds[i]),
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  if (value == true) {
                    _selectedMembers.add(widget.memberIds[i]);
                  } else {
                    if (_selectedMembers.length > 1) {
                      _selectedMembers.remove(widget.memberIds[i]);
                    }
                  }
                  _updateSplits();
                });
              },
              activeColor: theme.colorScheme.primary,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
            ),
            if (i < widget.memberIds.length - 1)
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomSplitView(String currencySymbol, ThemeData theme) {
    return Column(
      children: [
        for (int i = 0; i < widget.memberIds.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BeityCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.memberNames[i],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSpacing.gapMD,
                  SizedBox(
                    width: 140,
                    child: BeityTextField(
                      controller: _amountControllers[widget.memberIds[i]],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0.00',
                      suffixText: currencySymbol,
                      onChanged: (value) {
                        final val = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _customAmounts[widget.memberIds[i]] = (val * 100).round();
                          _updateSplits();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPercentageSplitView(String currencySymbol, ThemeData theme) {
    return Column(
      children: [
        for (int i = 0; i < widget.memberIds.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BeityCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberNames[i],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Calculate & show actual currency preview next to percentage field
                        Text(
                          '${((widget.totalAmount * (_percentages[widget.memberIds[i]] ?? 0.0) / 100.0) / 100.0).toStringAsFixed(2)} $currencySymbol',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMD,
                  SizedBox(
                    width: 120,
                    child: BeityTextField(
                      controller: _percentageControllers[widget.memberIds[i]],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0.0',
                      suffixText: '%',
                      onChanged: (value) {
                        final val = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _percentages[widget.memberIds[i]] = val;
                          _updateSplits();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSharesSplitView(String currencySymbol, ThemeData theme) {
    final totalShares = _shares.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        for (int i = 0; i < widget.memberIds.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BeityCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberNames[i],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Display dynamically calculated share money value
                        Text(
                          '${(totalShares > 0 ? (widget.totalAmount * (_shares[widget.memberIds[i]] ?? 0.0) / totalShares) / 100.0 : 0.0).toStringAsFixed(2)} $currencySymbol',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMD,
                  SizedBox(
                    width: 120,
                    child: BeityTextField(
                      controller: _sharesControllers[widget.memberIds[i]],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0',
                      suffixText: context.translate('shares').replaceAll(' %', '').replaceAll(' Paylar', '').replaceAll(' حصص', 'حصة'),
                      onChanged: (value) {
                        final val = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _shares[widget.memberIds[i]] = val;
                          _updateSplits();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomValidator(String currencySymbol, ThemeData theme) {
    switch (_splitType) {
      case SplitType.equally:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              AppSpacing.gapMD,
              Expanded(
                child: Text(
                  context.translate('split_equally_msg', arguments: {'count': _selectedMembers.length.toString()}),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        );
      case SplitType.custom:
        final currentTotal = _customAmounts.values.fold(0, (sum, val) => sum + val);
        final diff = widget.totalAmount - currentTotal;
        final isMatched = diff == 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isMatched
                ? AppColors.success.withValues(alpha: 0.1)
                : theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isMatched
                  ? AppColors.success.withValues(alpha: 0.2)
                  : theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isMatched ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isMatched ? AppColors.success : theme.colorScheme.error,
                size: 20,
              ),
              AppSpacing.gapMD,
              Expanded(
                child: Text(
                  isMatched
                      ? context.translate('total_matches')
                      : context.translate('remaining_distribute', arguments: {'amount': (diff / 100).toStringAsFixed(2)}),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMatched ? AppColors.success : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      case SplitType.percentage:
        final totalPct = _percentages.values.fold(0.0, (sum, val) => sum + val);
        final isMatched = (totalPct - 100.0).abs() < 0.01;
        final diff = 100.0 - totalPct;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isMatched
                ? AppColors.success.withValues(alpha: 0.1)
                : theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isMatched
                  ? AppColors.success.withValues(alpha: 0.2)
                  : theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isMatched ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isMatched ? AppColors.success : theme.colorScheme.error,
                size: 20,
              ),
              AppSpacing.gapMD,
              Expanded(
                child: Text(
                  isMatched
                      ? context.translate('sum_percentages_match')
                      : context.translate('percentage_sum_warning', arguments: {
                          'current': totalPct.toStringAsFixed(1),
                          'remaining': diff.toStringAsFixed(1)
                        }),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMatched ? AppColors.success : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      case SplitType.shares:
        final totalShares = _shares.values.fold(0.0, (sum, val) => sum + val);
        final isValid = totalShares > 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isValid
                ? AppColors.success.withValues(alpha: 0.1)
                : theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isValid
                  ? AppColors.success.withValues(alpha: 0.2)
                  : theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isValid ? AppColors.success : theme.colorScheme.error,
                size: 20,
              ),
              AppSpacing.gapMD,
              Expanded(
                child: Text(
                  isValid
                      ? context.translate('total_shares_count', arguments: {'count': totalShares.toString()})
                      : context.translate('shares_error_msg'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isValid ? AppColors.success : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
