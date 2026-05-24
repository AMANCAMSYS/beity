import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../domain/entities/ai_mode.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/entities/ai_assistant_request.dart';
import '../../domain/entities/ai_meal.dart';

import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_mode_selector.dart';
import '../widgets/ai_smart_chips.dart';
import '../widgets/ai_clarifying_questions.dart';
import '../widgets/ai_meal_card.dart';
import '../widgets/ai_recipe_checklist.dart';
import '../widgets/ai_weekly_plan_view.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listTitle;
  final String homeId;
  final String homeType;
  final List<String> existingItemNames;

  const AiAssistantScreen({
    super.key,
    required this.listId,
    this.listTitle = 'قائمة',
    this.homeId = '',
    this.homeType = 'family',
    this.existingItemNames = const [],
  });

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  AiMode _selectedMode = AiMode.whatToCook;
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    ActionDebouncer.execute(() async {
      final request = AiAssistantRequest(
        mode: _selectedMode,
        userPrompt: prompt,
        language: 'ar',
        homeType: widget.homeType,
        listTitle: widget.listTitle,
        existingShoppingItems: widget.existingItemNames,
      );
      await ref.read(aiAssistantProvider.notifier).sendRequest(request);
    });
  }

  void _onChipSelected(String text) {
    final currentText = _promptController.text.trim();
    if (currentText.isEmpty) {
      _promptController.text = text;
    } else {
      _promptController.text = '$currentText - $text';
    }
    _sendRequest();
  }

  void _onQuickOptionSelected(String option) {
    final currentText = _promptController.text.trim();
    if (currentText.isEmpty) {
      _promptController.text = option;
    } else {
      _promptController.text = '$currentText - $option';
    }
    _sendRequest();
  }

  void _showRecipeIngredientsInstantly(String mealName, String description, List<String> mainIngredients, int estimatedTimeMinutes, int servings) {
    ref.read(aiAssistantProvider.notifier).showMealIngredientsInstantly(
      mealName: mealName,
      description: description,
      mainIngredients: mainIngredients,
      estimatedTimeMinutes: estimatedTimeMinutes,
      servings: servings,
    );
  }

  Future<void> _addSelectedToList() async {
    final notifier = ref.read(aiAssistantProvider.notifier);
    final success = await notifier.addSelectedToShoppingList(widget.listId);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة العناصر إلى القائمة بنجاح')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المساعد الذكي'),
          centerTitle: true,
          actions: [
            if (state is AiAssistantResult && state.response is AiRecipeIngredientsResponse)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'select_all') {
                    ref.read(aiAssistantProvider.notifier).selectAllMissing();
                  } else if (value == 'deselect_all') {
                    ref.read(aiAssistantProvider.notifier).deselectAll();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'select_all', child: Text('تحديد كل الناقص')),
                  const PopupMenuItem(value: 'deselect_all', child: Text('إلغاء التحديد')),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            // Mode selector
            const SizedBox(height: 8),
            AiModeSelector(
              selectedMode: _selectedMode,
              onModeChanged: (mode) {
                setState(() => _selectedMode = mode);
                _promptController.clear();
                ref.read(aiAssistantProvider.notifier).reset();
              },
            ),
            const SizedBox(height: 12),

            // Smart chips
            AiSmartChips(onChipSelected: _onChipSelected),
            const SizedBox(height: 12),

            // Prompt input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: _getHintText(),
                          hintTextDirection: TextDirection.rtl,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendRequest(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 6, right: 6),
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: state is AiAssistantLoading ? null : _sendRequest,
                          child: SizedBox(
                            width: 44, height: 44,
                            child: Center(
                              child: state is AiAssistantLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Results area
            Expanded(
              child: _buildResultArea(state, isDark),
            ),
          ],
        ),

        // FAB for adding selected items
        floatingActionButton: _buildFAB(state),
      ),
    );
  }

  Widget _buildResultArea(AiAssistantState state, bool isDark) {
    if (state is AiAssistantIdle) {
      return _buildIdleView(isDark);
    }

    if (state is AiAssistantLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('جاري التفكير...', style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    }

    if (state is AiAssistantError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sendRequest,
                icon: const Icon(Icons.refresh),
                label: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is AiAssistantAddingItems) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('جاري إضافة العناصر...', style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    }

    if (state is AiAssistantResult) {
      return _buildResponseView(state.response, isDark);
    }

    return const SizedBox.shrink();
  }

  Widget _buildResponseView(AiResponse response, bool isDark) {
    switch (response) {
      case AiClarifyingResponse():
        return SingleChildScrollView(
          child: AiClarifyingQuestions(
            questions: response.questions,
            quickOptions: response.quickOptions,
            onOptionSelected: _onQuickOptionSelected,
          ),
        );

      case AiShoppingSuggestionsResponse():
        if (response.suggestions.isEmpty) {
          return _buildEmptyState('لم يتم العثور على اقتراحات');
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: response.suggestions.length,
          itemBuilder: (context, index) {
            final s = response.suggestions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${s.quantity} ${s.unit ?? 'قطعة'}${s.category != null ? ' • ${s.category}' : ''}',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                        ),
                        if (s.reason != null && s.reason!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(s.reason!, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.accent)),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_outline, color: AppColors.primary.withValues(alpha: 0.5)),
                ],
              ),
            );
          },
        );

      case AiMealSuggestionsResponse():
        if (response.meals.isEmpty) {
          return _buildEmptyState('لم يتم العثور على وجبات');
        }
        return ListView(
          controller: _scrollController,
          children: [
            if (response.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(response.summary, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ),
            ...response.meals.map((meal) => AiMealCard(
              meal: meal,
              onShowIngredients: () => _showRecipeIngredientsInstantly(meal.name, meal.description, meal.mainIngredients, meal.estimatedTimeMinutes, meal.servings),
            )),
          ],
        );

      case AiRecipeIngredientsResponse():
        return AiRecipeChecklist(
          meal: response.meal,
          ingredients: response.ingredients,
          optionalIngredients: response.optionalIngredients,
          cookingStepsPreview: response.cookingStepsPreview,
          shoppingSummary: response.shoppingSummary,
        );

      case AiWeeklyPlanResponse():
        return AiWeeklyPlanView(
          plan: response.plan,
          onShowIngredients: (mealName, description, mainIngredients, time, servings) => 
            _showRecipeIngredientsInstantly(mealName, description, mainIngredients, time, servings),
        );

      case AiPantryMealsResponse():
        if (response.meals.isEmpty) {
          return _buildEmptyState('لم يتم العثور على وجبات');
        }
        return ListView(
          controller: _scrollController,
          children: [
            if (response.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(response.summary, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ),
            ...response.meals.map((meal) => AiMealCard(
              meal: AiMeal(
                name: meal.name,
                description: meal.description,
                difficulty: meal.difficulty,
                estimatedTimeMinutes: meal.estimatedTimeMinutes,
                servings: meal.servings,
                cuisine: meal.cuisine,
                whyThisMeal: meal.whyThisMeal,
                tags: meal.tags,
              ),
              isPantryMeal: true,
              availableIngredients: meal.availableIngredients,
              missingIngredients: meal.missingIngredients,
              onShowIngredients: () => _showRecipeIngredientsInstantly(meal.name, meal.description, [...meal.availableIngredients, ...meal.missingIngredients], meal.estimatedTimeMinutes, meal.servings),
            )),
          ],
        );

      case AiNotRelatedResponse():
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(response.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        );

      case AiErrorResponse():
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(response.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.error)),
          ),
        );
    }
  }

  Widget? _buildFAB(AiAssistantState state) {
    if (state is AiAssistantResult && state.response is AiRecipeIngredientsResponse) {
      final count = state.selectedIngredientIndices.length;
      if (count == 0) return null;

      return FloatingActionButton.extended(
        onPressed: _addSelectedToList,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: Text(
          'أضف $count إلى القائمة',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    }
    return null;
  }

  Widget _buildIdleView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryLight.withValues(alpha: 0.08)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            Text(
              'المساعد الذكي',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر الوضع واكتب ما تريد وسأساعدك',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedMode) {
      case AiMode.shoppingSuggestions: return 'مثال: عشاء لعائلة من 5';
      case AiMode.whatToCook: return 'مثال: أريد وجبة سريعة';
      case AiMode.recipeIngredients: return 'مثال: كبسة دجاج';
      case AiMode.cookByVegetables: return 'مثال: عندي بطاطس وبصل';
      case AiMode.cookBySpices: return 'مثال: عندي كمون وكركم';
      case AiMode.cookByAvailable: return 'مثال: عندي دجاج وأرز';
      case AiMode.budgetMeals: return 'مثال: وجبة اقتصادية لـ 4 أشخاص';
      case AiMode.healthyMeals: return 'مثال: وجبة صحية خفيفة';
      case AiMode.quickMeals: return 'مثال: وجبة في 15 دقيقة';
      case AiMode.kidsMeals: return 'مثال: وجبة للأطفال';
      case AiMode.guestMeals: return 'مثال: عزومة 10 أشخاص';
      case AiMode.weeklyMealPlan: return 'مثال: خطة أسبوع لعائلة';
      case AiMode.ramadanList: return 'مثال: مقاضي رمضان';
      case AiMode.travelList: return 'مثال: رحلة 3 أيام';
      case AiMode.cleaningList: return 'مثال: تنظيف المطبخ';
    }
  }
}
