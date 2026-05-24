import 'package:flutter/material.dart';
import '../../domain/entities/ai_recipe_ingredient.dart';
import '../../../../app/theme/app_colors.dart';

/// Status badge widget for ingredient availability status.
class AiStatusBadge extends StatelessWidget {
  final IngredientStatus status;

  const AiStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final (color, bgColor, label) = _badgeConfig(isArabic);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  (Color, Color, String) _badgeConfig(bool isArabic) {
    switch (status) {
      case IngredientStatus.available:
        return (AppColors.success, AppColors.success.withValues(alpha: 0.12), isArabic ? 'موجود' : 'Available');
      case IngredientStatus.missing:
        return (AppColors.error, AppColors.error.withValues(alpha: 0.12), isArabic ? 'ناقص' : 'Missing');
      case IngredientStatus.alreadyInList:
        return (AppColors.info, AppColors.info.withValues(alpha: 0.12), isArabic ? 'في القائمة' : 'In List');
      case IngredientStatus.optional:
        return (AppColors.warning, AppColors.warning.withValues(alpha: 0.12), isArabic ? 'اختياري' : 'Optional');
      case IngredientStatus.unknown:
        return (Colors.grey, Colors.grey.withValues(alpha: 0.12), isArabic ? 'غير معروف' : 'Unknown');
    }
  }
}
