import 'package:flutter/material.dart';
import '../../domain/entities/ai_mode.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// Quick prompt chips for common requests.
class AiSmartChips extends StatelessWidget {
  final ValueChanged<String> onChipSelected;
  final ValueChanged<AiMode>? onModeChanged;

  const AiSmartChips({super.key, required this.onChipSelected, this.onModeChanged});

  static const _chipKeys = [
    'ai_chip_quick_meal',
    'ai_chip_budget_meal',
    'ai_chip_chicken',
    'ai_chip_vegetarian',
    'ai_chip_kids',
    'ai_chip_guests',
    'ai_chip_healthy',
    'ai_chip_ramadan',
  ];

  // Map chip index to the appropriate AI mode
  static const _chipModes = [
    AiMode.quickMeals,      // وجبة سريعة
    AiMode.budgetMeals,     // وجبة اقتصادية
    AiMode.whatToCook,      // بالدجاج
    AiMode.cookByVegetables, // بالخضار
    AiMode.kidsMeals,       // للأطفال
    AiMode.guestMeals,      // للضيوف
    AiMode.healthyMeals,    // صحية
    AiMode.ramadanList,     // رمضان
  ];

  @override
  Widget build(BuildContext context) {
    final chips = _chipKeys.map((key) => context.translate(key)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Switch to the appropriate mode first
              if (onModeChanged != null) {
                onModeChanged!(_chipModes[index]);
              }
              // Then set the chip text
              onChipSelected(chips[index]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                chips[index],
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
