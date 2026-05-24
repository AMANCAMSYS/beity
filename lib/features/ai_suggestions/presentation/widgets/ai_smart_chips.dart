import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Quick prompt chips for common requests.
class AiSmartChips extends StatelessWidget {
  final ValueChanged<String> onChipSelected;

  const AiSmartChips({super.key, required this.onChipSelected});

  static const _chipsAr = [
    'وجبة سريعة',
    'وجبة اقتصادية',
    'بالدجاج',
    'بالخضار',
    'للأطفال',
    'للضيوف',
    'صحية',
    'رمضان',
  ];

  static const _chipsEn = [
    'Quick Meal',
    'Budget Meal',
    'Chicken',
    'Vegetarian',
    'For Kids',
    'For Guests',
    'Healthy',
    'Ramadan',
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final chips = isArabic ? _chipsAr : _chipsEn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onChipSelected(chips[index]),
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
                style: TextStyle(
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
