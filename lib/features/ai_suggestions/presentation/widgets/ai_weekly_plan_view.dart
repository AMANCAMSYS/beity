import 'package:flutter/material.dart';
import '../../domain/entities/ai_weekly_plan.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/sawa_cached_image.dart';

/// Displays a weekly meal plan with expandable day sections.
class AiWeeklyPlanView extends StatefulWidget {
  final AiWeeklyPlan plan;
  final void Function(String mealName, String description, List<String> mainIngredients, int estimatedTimeMinutes, int servings)? onShowIngredients;

  const AiWeeklyPlanView({super.key, required this.plan, this.onShowIngredients});

  @override
  State<AiWeeklyPlanView> createState() => _AiWeeklyPlanViewState();
}

class _AiWeeklyPlanViewState extends State<AiWeeklyPlanView> {
  late Set<int> _expandedDays;

  @override
  void initState() {
    super.initState();
    // Expand first day by default
    _expandedDays = {0};
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.plan.days.length + (widget.plan.summary.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.plan.summary.isNotEmpty && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.plan.summary,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.5),
              ),
            );
          }

          final dayIndex = index - (widget.plan.summary.isNotEmpty ? 1 : 0);
          final day = widget.plan.days[dayIndex];
          final isExpanded = _expandedDays.contains(dayIndex);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                // Day header
                InkWell(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedDays.remove(dayIndex);
                    } else {
                      _expandedDays.add(dayIndex);
                    }
                  }),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              day.day.length > 2 ? day.day.substring(0, 2) : day.day,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day.day, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                context.translate('meals_count', arguments: {'count': day.meals.length.toString()}),
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded meals
                if (isExpanded)
                  ...day.meals.map((meal) => Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Small thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50, height: 50,
                                child: SawaCachedImage(
                                  imageUrl: 'https://tse2.mm.bing.net/th?q=${Uri.encodeComponent('${meal.name} food recipe')}&w=150&h=150&c=7&rs=1&p=0',
                                  fit: BoxFit.cover,
                                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                  errorWidget: Container(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                    child: const Icon(Icons.restaurant_rounded, size: 20, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (meal.mealType.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _mealTypeColor(meal.mealType).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _mealTypeLabel(meal.mealType),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _mealTypeColor(meal.mealType)),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (meal.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(meal.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${meal.estimatedTimeMinutes} ${context.translate('minutes_short')}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                            ),
                            const Spacer(),
                            if (widget.onShowIngredients != null)
                              GestureDetector(
                                onTap: () => widget.onShowIngredients!(meal.name, meal.description, meal.mainIngredients, meal.estimatedTimeMinutes, 4),
                                child: Text(
                                  context.translate('show_ingredients'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _mealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return AppColors.warning;
      case 'lunch': return AppColors.primary;
      case 'dinner': return AppColors.secondary;
      case 'snack': return AppColors.info;
      case 'dessert': return AppColors.accent;
      default: return Colors.grey;
    }
  }

  String _mealTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
      case 'snack':
      case 'dessert':
        return context.translate(type.toLowerCase());
      default: return type;
    }
  }
}
