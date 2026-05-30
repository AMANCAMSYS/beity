import 'package:flutter/material.dart';
import '../../domain/entities/ai_meal.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/beity_cached_image.dart';

/// Card widget displaying a single meal suggestion.
class AiMealCard extends StatelessWidget {
  final AiMeal meal;
  final VoidCallback? onShowIngredients;
  final bool isPantryMeal;
  final List<String> availableIngredients;
  final List<String> missingIngredients;

  const AiMealCard({
    super.key,
    required this.meal,
    this.onShowIngredients,
    this.isPantryMeal = false,
    this.availableIngredients = const [],
    this.missingIngredients = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BeityCachedImage(
                  imageUrl: 'https://tse2.mm.bing.net/th?q=${Uri.encodeComponent('${meal.name} food recipe')}&w=600&h=400&c=7&rs=1&p=0',
                  fit: BoxFit.cover,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  placeholder: Container(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    child: const Center(child: Icon(Icons.restaurant_rounded, color: Colors.grey, size: 30)),
                  ),
                  errorWidget: Container(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    child: const Center(child: Icon(Icons.restaurant_rounded, color: Colors.grey, size: 30)),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                meal.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Description
            if (meal.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  meal.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Meta row (time, difficulty, servings)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _metaChip(Icons.timer_outlined, '${meal.estimatedTimeMinutes} ${context.translate('minutes_short')}', isDark),
                  const SizedBox(width: 8),
                  if (meal.difficulty.isNotEmpty)
                    _metaChip(Icons.signal_cellular_alt_rounded, meal.difficulty, isDark),
                  if (meal.difficulty.isNotEmpty) const SizedBox(width: 8),
                  _metaChip(Icons.people_outline_rounded, '${meal.servings}', isDark),
                ],
              ),
            ),

            // Tags
            if (meal.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: meal.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ),

            // Main ingredients
            if (meal.mainIngredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  meal.mainIngredients.join('، '),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Why this meal
            if (meal.whyThisMeal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meal.whyThisMeal,
                        style: const TextStyle(fontSize: 12, color: AppColors.accent, fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Pantry info (available vs missing)
            if (isPantryMeal && (availableIngredients.isNotEmpty || missingIngredients.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (availableIngredients.isNotEmpty)
                      _pantryRow(Icons.check_circle_outline, AppColors.success, 
                        '${context.translate('available')}: ${availableIngredients.join('، ')}', isDark),
                    if (missingIngredients.isNotEmpty)
                      _pantryRow(Icons.add_circle_outline, AppColors.warning, 
                        '${context.translate('missing')}: ${missingIngredients.join('، ')}', isDark),
                  ],
                ),
              ),

            // Show ingredients button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onShowIngredients,
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: Text(context.translate('show_ingredients')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _pantryRow(IconData icon, Color color, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
