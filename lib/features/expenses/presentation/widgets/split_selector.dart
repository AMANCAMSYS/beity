import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';

class SplitSelector extends StatefulWidget {
  final int totalAmount;
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
  bool _isEqualSplit = true;
  final Map<String, int> _customAmounts = {};
  final Map<String, TextEditingController> _controllers = {};
  Set<String> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    _selectedMembers = Set.from(widget.memberIds);
    for (var id in widget.memberIds) {
      _controllers[id] = TextEditingController();
    }
    _updateSplits();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateSplits() {
    List<({String memberId, int amount})> splits;

    if (_isEqualSplit) {
      splits = _calculateEqualSplits();
    } else {
      splits = _calculateCustomSplits();
    }

    widget.onChanged(splits);
  }

  List<({String memberId, int amount})> _calculateEqualSplits() {
    if (_selectedMembers.isEmpty) return [];

    final baseAmount = widget.totalAmount ~/ _selectedMembers.length;
    final remainder = widget.totalAmount % _selectedMembers.length;

    return _selectedMembers.map((memberId) {
      final amount =
          memberId == widget.payerId ? baseAmount + remainder : baseAmount;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  List<({String memberId, int amount})> _calculateCustomSplits() {
    return _selectedMembers.map((memberId) {
      final amount = _customAmounts[memberId] ?? 0;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'نوع التقسيم' : 'Split Type',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapSM,
        Row(
          children: [
            _buildSplitTypeChip(
              label: isArabic ? 'بالتساوي' : 'Equally',
              isSelected: _isEqualSplit,
              onSelected: () {
                setState(() {
                  _isEqualSplit = true;
                  _updateSplits();
                });
              },
              theme: theme,
            ),
            AppSpacing.gapSM,
            _buildSplitTypeChip(
              label: isArabic ? 'مخصص' : 'Custom',
              isSelected: !_isEqualSplit,
              onSelected: () {
                setState(() {
                  _isEqualSplit = false;
                  _updateSplits();
                });
              },
              theme: theme,
            ),
          ],
        ),
        AppSpacing.gapLG,
        Text(
          isArabic ? 'المشاركون في الدفع' : 'Who is splitting?',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapSM,
        if (_isEqualSplit) _buildEqualSplitView(isArabic, theme) else _buildCustomSplitView(isArabic, theme),
        
        if (!_isEqualSplit) ...[
          AppSpacing.gapLG,
          _buildTotalCheck(isArabic, theme),
        ],
      ],
    );
  }

  Widget _buildSplitTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required ThemeData theme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: isSelected ? null : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCheck(bool isArabic, ThemeData theme) {
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
          color: isMatched ? AppColors.success.withValues(alpha: 0.2) : theme.colorScheme.error.withValues(alpha: 0.2),
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
                  ? (isArabic ? 'المجموع متطابق' : 'Total matches')
                  : (isArabic 
                      ? 'المتبقي: ${(diff / 100).toStringAsFixed(2)} ر.س' 
                      : 'Remaining: ${(diff / 100).toStringAsFixed(2)} SAR'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isMatched ? AppColors.success : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualSplitView(bool isArabic, ThemeData theme) {
    return BeityCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < widget.memberIds.length; i++) ...[
            CheckboxListTile(
              title: Text(
                widget.memberNames[i],
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: _selectedMembers.contains(widget.memberIds[i]) ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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
              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            ),
            if (i < widget.memberIds.length - 1)
              Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomSplitView(bool isArabic, ThemeData theme) {
    return Column(
      children: [
        for (int i = 0; i < widget.memberIds.length; i++)
          if (_selectedMembers.contains(widget.memberIds[i]))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: BeityCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.memberNames[i],
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    AppSpacing.gapMD,
                    SizedBox(
                      width: 140,
                      child: BeityTextField(
                        controller: _controllers[widget.memberIds[i]],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        hintText: '0.00',
                        suffixIcon: Icon(Icons.currency_exchange_rounded),
                        onChanged: (value) {
                          final amount = (double.tryParse(value) ?? 0) * 100;
                          setState(() {
                            _customAmounts[widget.memberIds[i]] = amount.round();
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
}
