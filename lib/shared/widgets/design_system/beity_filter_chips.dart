import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

class BeityFilterChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  const BeityFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: compact ? 36 : 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return FilterChip(
            label: Text(labels[index]),
            selected: isSelected,
            onSelected: (_) => onSelected(index),
            selectedColor: isDark
                ? AppColors.primaryLight.withValues(alpha: 0.2)
                : AppColors.primaryContainer,
            checkmarkColor: isDark ? AppColors.primaryLight : AppColors.primary,
            labelStyle: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : theme.colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 8,
              vertical: compact ? 0 : 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          );
        },
      ),
    );
  }
}
