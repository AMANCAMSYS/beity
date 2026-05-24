import 'package:flutter/material.dart';
import '../../domain/entities/ai_mode.dart';
import '../../../../app/theme/app_colors.dart';

/// Horizontal scrollable mode selector chips.
class AiModeSelector extends StatelessWidget {
  final AiMode selectedMode;
  final ValueChanged<AiMode> onModeChanged;

  const AiModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  static const _modeIcons = <AiMode, IconData>{
    AiMode.shoppingSuggestions: Icons.shopping_cart_rounded,
    AiMode.whatToCook: Icons.restaurant_menu_rounded,
    AiMode.recipeIngredients: Icons.receipt_long_rounded,
    AiMode.cookByVegetables: Icons.eco_rounded,
    AiMode.cookBySpices: Icons.local_fire_department_rounded,
    AiMode.cookByAvailable: Icons.kitchen_rounded,
    AiMode.budgetMeals: Icons.savings_rounded,
    AiMode.healthyMeals: Icons.favorite_rounded,
    AiMode.quickMeals: Icons.timer_rounded,
    AiMode.kidsMeals: Icons.child_care_rounded,
    AiMode.guestMeals: Icons.people_rounded,
    AiMode.weeklyMealPlan: Icons.calendar_month_rounded,
    AiMode.ramadanList: Icons.nights_stay_rounded,
    AiMode.travelList: Icons.flight_rounded,
    AiMode.cleaningList: Icons.cleaning_services_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: AiMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = AiMode.values[index];
          final isSelected = mode == selectedMode;
          final icon = _modeIcons[mode] ?? Icons.auto_awesome;

          return GestureDetector(
            onTap: () => onModeChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mode.label(isArabic ? 'ar' : 'en'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
