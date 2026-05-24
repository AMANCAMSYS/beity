import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ai_recipe_ingredient.dart';
import '../providers/ai_assistant_provider.dart';
import 'ai_status_badge.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// Vertical ingredient checklist with status badges and selection.
class AiRecipeChecklist extends ConsumerWidget {
  final AiMealInfo meal;
  final List<AiRecipeIngredient> ingredients;
  final List<AiRecipeIngredient> optionalIngredients;
  final List<String> cookingStepsPreview;
  final ShoppingSummary shoppingSummary;

  const AiRecipeChecklist({
    super.key,
    required this.meal,
    required this.ingredients,
    this.optionalIngredients = const [],
    this.cookingStepsPreview = const [],
    this.shoppingSummary = const ShoppingSummary(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(aiAssistantProvider);

    Set<int> selectedIndices = {};
    if (state is AiAssistantResult) {
      selectedIndices = state.selectedIngredientIndices;
    } else if (state is AiAssistantAddingItems) {
      selectedIndices = state.selectedIngredientIndices;
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meal header
          _buildMealHeader(context, isDark, isArabic),
          const SizedBox(height: 16),

          // Summary bar
          _buildSummaryBar(context, isDark, isArabic),
          const SizedBox(height: 16),

          // Required ingredients section
          Text(
            isArabic ? 'المكونات الأساسية' : 'Required Ingredients',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...ingredients.asMap().entries.map((e) => _buildIngredientTile(
            context, ref, e.value, e.key, selectedIndices.contains(e.key), isDark, isArabic,
          )),

          // Optional ingredients
          if (optionalIngredients.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              isArabic ? 'مكونات اختيارية' : 'Optional Ingredients',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            ...optionalIngredients.map((ing) => _buildOptionalTile(context, ing, isDark, isArabic)),
          ],

          // Cooking steps preview
          if (cookingStepsPreview.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              isArabic ? 'خطوات الطبخ' : 'Cooking Steps',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...cookingStepsPreview.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.value, style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMealHeader(BuildContext context, bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primaryLight.withValues(alpha: 0.04)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (meal.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(meal.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip(Icons.timer_outlined, '${meal.estimatedTimeMinutes} ${isArabic ? 'د' : 'min'}', isDark),
              const SizedBox(width: 8),
              _infoChip(Icons.people_outline, '${meal.servings} ${isArabic ? 'أشخاص' : 'servings'}', isDark),
              if (meal.difficulty.isNotEmpty) ...[
                const SizedBox(width: 8),
                _infoChip(Icons.signal_cellular_alt, meal.difficulty, isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, bool isDark, bool isArabic) {
    return Row(
      children: [
        _summaryChip(AppColors.success, '${shoppingSummary.availableCount}', isArabic ? 'موجود' : 'Available'),
        const SizedBox(width: 8),
        _summaryChip(AppColors.error, '${shoppingSummary.missingCount}', isArabic ? 'ناقص' : 'Missing'),
        const SizedBox(width: 8),
        _summaryChip(AppColors.info, '${shoppingSummary.alreadyInListCount}', isArabic ? 'في القائمة' : 'In List'),
      ],
    );
  }

  Widget _buildIngredientTile(BuildContext context, WidgetRef ref, AiRecipeIngredient ing, int index, bool isSelected, bool isDark, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.06)
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => ref.read(aiAssistantProvider.notifier).toggleIngredientSelection(index),
        title: Row(
          children: [
            Expanded(
              child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ),
            AiStatusBadge(status: ing.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${ing.quantity} ${ing.unit ?? (isArabic ? 'قطعة' : 'pcs')}',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  if (ing.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(ing.category!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                    ),
                  ],
                ],
              ),
              if (ing.reason != null && ing.reason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    ing.reason!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.info,
                    ),
                  ),
                ),
            ],
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildOptionalTile(BuildContext context, AiRecipeIngredient ing, bool isDark, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                  '${ing.quantity} ${ing.unit ?? (isArabic ? 'قطعة' : 'pcs')}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                ),
                if (ing.reason != null)
                  Text(ing.reason!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.warning)),
              ],
            ),
          ),
          AiStatusBadge(status: IngredientStatus.optional),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, bool isDark) {
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

  Widget _summaryChip(Color color, String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
