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
import '../widgets/ai_status_badge.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../../shared/widgets/design_system/sawa_empty_state.dart';
import '../../../../shared/widgets/design_system/sawa_skeleton_list.dart';
import '../../../activity_logs/domain/entities/activity_log.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';

import '../../../settings/presentation/providers/app_settings_provider.dart';

class AiSuggestionsScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listTitle;
  final String homeId;
  final String homeType;

  const AiSuggestionsScreen({
    super.key,
    required this.listId,
    this.listTitle = 'default_list_name',
    this.homeId = '',
    this.homeType = 'family',
  });

  @override
  ConsumerState<AiSuggestionsScreen> createState() =>
      _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends ConsumerState<AiSuggestionsScreen> {
  AiMode _selectedMode = AiMode.shoppingSuggestions;
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<(List<String>, List<String>, Map<String, String>)> _gatherLocalContext(
    String localeCode,
  ) async {
    return ref.read(
      aiLocalContextProvider((
        widget.homeId,
        widget.listId,
        widget.listTitle,
        localeCode,
      )).future,
    );
  }

  void _sendRequest() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    ActionDebouncer.execute(() async {
      final localeCode = Localizations.localeOf(context).languageCode;

      // Start loading immediately so UI updates
      ref.read(aiAssistantProvider.notifier).startLoading();

      // Gather context asynchronously
      final contextData = await _gatherLocalContext(localeCode);

      if (!mounted) return;
      final settings = ref.read(appSettingsProvider);

      final request = AiAssistantRequest(
        mode: _selectedMode,
        userPrompt: prompt,
        language: localeCode,
        homeId: widget.homeId,
        listId: widget.listId,
        homeType: widget.homeType,
        listTitle: widget.listTitle,
        existingShoppingItems: contextData.$1,
        inventoryItems: contextData.$2,
        userTerms: contextData.$3,
        country: settings.country,
        dialect: settings.dialect,
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

  void _showRecipeIngredientsInstantly(
    String mealName,
    String description,
    List<String> mainIngredients,
    int estimatedTimeMinutes,
    int servings,
  ) {
    final localeCode = Localizations.localeOf(context).languageCode;
    ActionDebouncer.execute(() async {
      final contextData = await _gatherLocalContext(localeCode);
      final settings = ref.read(appSettingsProvider);

      ref
          .read(aiAssistantProvider.notifier)
          .getRecipeIngredients(
            mealName: mealName,
            language: localeCode,
            homeId: widget.homeId,
            listId: widget.listId,
            existingShoppingItems: contextData.$1,
            inventoryItems: contextData.$2,
            userTerms: contextData.$3,
            homeType: widget.homeType,
            listTitle: widget.listTitle,
            country: settings.country,
            dialect: settings.dialect,
          );
    });
  }

  Future<void> _addSelectedItems() async {
    final notifier = ref.read(aiAssistantProvider.notifier);
    final state = ref.read(aiAssistantProvider);
    Set<int> selectedIndices = {};
    if (state is AiAssistantResult) {
      selectedIndices = state.selectedIngredientIndices;
    } else if (state is AiAssistantAddingItems) {
      selectedIndices = state.selectedIngredientIndices;
    }

    if (selectedIndices.isEmpty) return;

    final success = await notifier.addSelectedToShoppingList(
      widget.listId,
      widget.homeId,
    );

    if (!mounted) return;
    if (success) {
      try {
        final activityRepo = ref.read(activityLogRepositoryProvider);
        await activityRepo.logActivity(
          homeId: widget.homeId,
          action: ActionType.aiItemsAdded,
          entityType: EntityType.shoppingList,
          entityId: widget.listId,
          entityName: widget.listTitle,
          metadata: {
            'source': 'ai_suggestion',
            'items_count': selectedIndices.length,
          },
        );
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          content: Text(
            context.translate(
              'added_x_items_successfully',
              arguments: {'count': selectedIndices.length.toString()},
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('ai_assistant')),
        centerTitle: true,
        actions: [
          if (state is AiAssistantResult &&
              (state.response is AiRecipeIngredientsResponse ||
                  state.response is AiShoppingSuggestionsResponse))
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'select_all') {
                  ref.read(aiAssistantProvider.notifier).selectAllMissing();
                } else if (value == 'deselect_all') {
                  ref.read(aiAssistantProvider.notifier).deselectAll();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'select_all',
                  child: Text(
                    state.response is AiRecipeIngredientsResponse ||
                            state.response is AiShoppingSuggestionsResponse
                        ? context.translate('select_all_missing')
                        : context.translate('select_all'),
                  ),
                ),
                PopupMenuItem(
                  value: 'deselect_all',
                  child: Text(context.translate('deselect_all')),
                ),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        hintText: _getHintText(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                        onTap: state is AiAssistantLoading
                            ? null
                            : _sendRequest,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: state is AiAssistantLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
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
          Expanded(child: _buildResultArea(state, isDark)),
          if (state is AiAssistantResult &&
              (state.response is AiRecipeIngredientsResponse ||
                  state.response is AiShoppingSuggestionsResponse))
            _buildBottomBar(state, isDark),
          if (state is AiAssistantAddingItems) _buildBottomBar(state, isDark),
        ],
      ),

      // FAB for adding selected items
    );
  }

  Widget _buildResultArea(AiAssistantState state, bool isDark) {
    if (state is AiAssistantIdle) {
      return _buildIdleView(isDark);
    }

    if (state is AiAssistantLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.translate('ai_thinking'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SawaSkeletonList(itemCount: 5, itemHeight: 85),
        ],
      );
    }

    if (state is AiAssistantError) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  context.translate(state.message),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _sendRequest,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.translate('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is AiAssistantAddingItems) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                context.translate('adding_items'),
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
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
          return _buildEmptyState(context.translate('no_suggestions_found'));
        }

        final state = ref.read(aiAssistantProvider);
        Set<int> selectedIndices = {};
        if (state is AiAssistantResult) {
          selectedIndices = state.selectedIngredientIndices;
        } else if (state is AiAssistantAddingItems) {
          selectedIndices = state.selectedIngredientIndices;
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: response.suggestions.length,
          itemBuilder: (context, index) {
            final s = response.suggestions[index];
            final isSelected = selectedIndices.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (_) => ref
                    .read(aiAssistantProvider.notifier)
                    .toggleIngredientSelection(index),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.displayName ?? s.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    AiStatusBadge(status: s.status),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.quantity} ${s.unit ?? context.translate('piece_unit')}${s.category != null ? ' • ${s.category}' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      if (s.reason != null && s.reason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            s.reason!,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        );

      case AiMealSuggestionsResponse():
        if (response.meals.isEmpty) {
          return _buildEmptyState(context.translate('no_meals_found'));
        }
        return ListView(
          controller: _scrollController,
          children: [
            if (response.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  response.summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ),
            ...response.meals.map(
              (meal) => AiMealCard(
                meal: meal,
                onShowIngredients: () => _showRecipeIngredientsInstantly(
                  meal.name,
                  meal.description,
                  meal.mainIngredients,
                  meal.estimatedTimeMinutes,
                  meal.servings,
                ),
              ),
            ),
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
          onShowIngredients:
              (mealName, description, mainIngredients, time, servings) =>
                  _showRecipeIngredientsInstantly(
                    mealName,
                    description,
                    mainIngredients,
                    time,
                    servings,
                  ),
        );

      case AiPantryMealsResponse():
        if (response.meals.isEmpty) {
          return _buildEmptyState(context.translate('no_meals_found'));
        }
        return ListView(
          controller: _scrollController,
          children: [
            if (response.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  response.summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ),
            ...response.meals.map(
              (meal) => AiMealCard(
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
                onShowIngredients: () => _showRecipeIngredientsInstantly(
                  meal.name,
                  meal.description,
                  [...meal.availableIngredients, ...meal.missingIngredients],
                  meal.estimatedTimeMinutes,
                  meal.servings,
                ),
              ),
            ),
          ],
        );

      case AiNotRelatedResponse():
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.translate(response.message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        );

      case AiErrorResponse():
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                context.translate(response.message),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.error),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildBottomBar(AiAssistantState state, bool isDark) {
    int selectedCount = 0;
    bool isAdding = false;

    if (state is AiAssistantResult) {
      selectedCount = state.selectedIngredientIndices.length;
    } else if (state is AiAssistantAddingItems) {
      selectedCount = state.selectedIngredientIndices.length;
      isAdding = true;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SawaButton(
                text: context.translate('cancel'),
                type: SawaButtonType.outline,
                onPressed: isAdding
                    ? null
                    : () {
                        ref.read(aiAssistantProvider.notifier).reset();
                        Navigator.of(context).pop();
                      },
              ),
            ),
            AppSpacing.gapMD,
            Expanded(
              flex: 2,
              child: SawaButton(
                text: context.translate(
                  'add_selected',
                  arguments: {'count': selectedCount.toString()},
                ),
                onPressed: (selectedCount == 0 || isAdding)
                    ? null
                    : _addSelectedItems,
                isLoading: isAdding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primaryLight.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 40,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.translate('ai_assistant'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.translate('ai_assistant_idle_desc'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SawaEmptyState(
      title: context.translate('no_suggestions'),
      message: message,
      icon: Icons.search_off_rounded,
    );
  }

  String _getHintText() {
    switch (_selectedMode) {
      case AiMode.shoppingSuggestions:
        return context.translate('ai_hint_shoppingSuggestions');
      case AiMode.whatToCook:
        return context.translate('ai_hint_whatToCook');
      case AiMode.recipeIngredients:
        return context.translate('ai_hint_recipeIngredients');
      case AiMode.cookByVegetables:
        return context.translate('ai_hint_cookByVegetables');
      case AiMode.cookBySpices:
        return context.translate('ai_hint_cookBySpices');
      case AiMode.cookByAvailable:
        return context.translate('ai_hint_cookByAvailable');
      case AiMode.budgetMeals:
        return context.translate('ai_hint_budgetMeals');
      case AiMode.healthyMeals:
        return context.translate('ai_hint_healthyMeals');
      case AiMode.quickMeals:
        return context.translate('ai_hint_quickMeals');
      case AiMode.kidsMeals:
        return context.translate('ai_hint_kidsMeals');
      case AiMode.guestMeals:
        return context.translate('ai_hint_guestMeals');
      case AiMode.weeklyMealPlan:
        return context.translate('ai_hint_weeklyMealPlan');
      case AiMode.ramadanList:
        return context.translate('ai_hint_ramadanList');
      case AiMode.travelList:
        return context.translate('ai_hint_travelList');
      case AiMode.cleaningList:
        return context.translate('ai_hint_cleaningList');
    }
  }
}
