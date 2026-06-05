import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../domain/entities/ai_recipe_ingredient.dart';
import '../../../../app/theme/app_colors.dart';

/// Status badge widget for ingredient availability status.
class AiStatusBadge extends StatelessWidget {
  final IngredientStatus status;

  const AiStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = _badgeConfig(context);

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

  (Color, Color, String) _badgeConfig(BuildContext context) {
    switch (status) {
      case IngredientStatus.available:
        return (AppColors.success, AppColors.success.withValues(alpha: 0.12), context.translate('available'));
      case IngredientStatus.missing:
        return (AppColors.error, AppColors.error.withValues(alpha: 0.12), context.translate('missing'));
      case IngredientStatus.alreadyInList:
        return (AppColors.info, AppColors.info.withValues(alpha: 0.12), context.translate('in_list'));
      case IngredientStatus.inCurrentList:
        return (AppColors.info, AppColors.info.withValues(alpha: 0.12), context.translate('in_current_list'));
      case IngredientStatus.inOtherList:
        return (AppColors.warning, AppColors.warning.withValues(alpha: 0.12), context.translate('in_other_list'));
      case IngredientStatus.optional:
        return (AppColors.warning, AppColors.warning.withValues(alpha: 0.12), context.translate('optional'));
      case IngredientStatus.unknown:
        return (Colors.grey, Colors.grey.withValues(alpha: 0.12), context.translate('unknown'));
    }
  }
}
