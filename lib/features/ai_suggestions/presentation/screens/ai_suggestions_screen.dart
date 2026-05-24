import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/ai_suggestions_provider.dart';
import '../widgets/ai_prompt_input.dart';
import '../widgets/ai_suggestions_list.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../activity_logs/domain/entities/activity_log.dart';

class AiSuggestionsScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listTitle;
  final String homeId;
  final String homeType;
  final List<String> existingItemNames;

  const AiSuggestionsScreen({
    super.key,
    required this.listId,
    required this.listTitle,
    required this.homeId,
    required this.homeType,
    required this.existingItemNames,
  });

  @override
  ConsumerState<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends ConsumerState<AiSuggestionsScreen> {
  void _addSelectedItems() {
    ActionDebouncer.execute(() async {
      final state = ref.read(aiSuggestionsProvider);
      if (state is! AiSuggestionsSuccess) return;

      final selectedIndices = state.selectedIndices;
      if (selectedIndices.isEmpty) return;

      ref.read(aiSuggestionsProvider.notifier).setAddingState();

      final suggestions = state.suggestions;
      final selectedSuggestions = selectedIndices.map((i) => suggestions[i]).toList();

      final shoppingRepo = ref.read(shoppingListRepositoryProvider);
      final activityRepo = ref.read(activityLogRepositoryProvider);

      try {
        for (final suggestion in selectedSuggestions) {
          // Add items to shopping list
          await shoppingRepo.createShoppingItem(
            listId: widget.listId,
            name: suggestion.name,
            quantity: suggestion.quantity ?? 1.0,
          );
        }

        // Log activity
        await activityRepo.logActivity(
          homeId: widget.homeId,
          action: ActionType.aiItemsAdded,
          entityType: EntityType.shoppingList,
          entityId: widget.listId,
          entityName: widget.listTitle,
          metadata: {
            'source': 'ai_suggestion',
            'items_count': selectedSuggestions.length,
            'items': selectedSuggestions.map((e) => e.name).toList(),
          },
        );

        if (mounted) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              content: Text(
                isArabic 
                    ? 'تمت إضافة ${selectedSuggestions.length} عناصر بنجاح' 
                    : 'Added ${selectedSuggestions.length} items successfully'
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSuggestionsProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'اقتراحات ذكية' : 'AI Suggestions', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(aiSuggestionsProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          AiPromptInput(
            listTitle: widget.listTitle,
            homeType: widget.homeType,
            existingItemNames: widget.existingItemNames,
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: _buildBody(state, isArabic, theme),
          ),
          if (state is AiSuggestionsSuccess || state is AiSuggestionsAdding)
            _buildBottomBar(state, isArabic, theme),
        ],
      ),
    );
  }

  Widget _buildBody(AiSuggestionsState state, bool isArabic, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hintColor = (isDark ? AppColors.textHintDark : AppColors.textHintLight).withValues(alpha: 0.5);

    if (state is AiSuggestionsIdle) {
      return BeityEmptyState(
        title: isArabic ? 'ماذا يدور في ذهنك؟' : 'What\'s on your mind?',
        message: isArabic 
            ? 'اكتب ما تحتاجه للحصول على اقتراحات ذكية لقائمة التسوق الخاصة بك' 
            : 'Type what you need to get smart suggestions for your shopping list',
        icon: Icons.auto_awesome_rounded,
      );
    } else if (state is AiSuggestionsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            AppSpacing.gapLG,
            Text(
              isArabic ? 'جارٍ تحليل طلبك وتحضير الاقتراحات...' : 'Analyzing request and preparing suggestions...',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (state is AiSuggestionsError) {
      return BeityEmptyState(
        title: isArabic ? 'عذراً، حدث خطأ' : 'Sorry, an error occurred',
        message: state.message,
        icon: Icons.error_outline_rounded,
        isError: true,
        actionText: isArabic ? 'إعادة المحاولة' : 'Retry',
        onAction: () {
          // The prompt input handles its own retry via notifier calls
        },
      );
    } else if (state is AiSuggestionsSuccess) {
      if (state.suggestions.isEmpty) {
        return BeityEmptyState(
          title: isArabic ? 'لا توجد اقتراحات' : 'No suggestions found',
          message: isArabic 
              ? 'لم نتمكن من العثور على اقتراحات لطلبك. جرب طلبًا مختلفًا أو أكثر تفصيلًا.' 
              : 'We couldn\'t find suggestions for your request. Try a different or more detailed prompt.',
          icon: Icons.search_off_rounded,
        );
      }
      return AiSuggestionsList(
        suggestions: state.suggestions,
        existingItemNames: widget.existingItemNames,
      );
    } else if (state is AiSuggestionsAdding) {
      return AiSuggestionsList(
        suggestions: state.suggestions,
        existingItemNames: widget.existingItemNames,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(AiSuggestionsState state, bool isArabic, ThemeData theme) {
    int selectedCount = 0;
    bool isAdding = false;
    if (state is AiSuggestionsSuccess) {
      selectedCount = state.selectedIndices.length;
    } else if (state is AiSuggestionsAdding) {
      selectedCount = state.selectedIndices.length;
      isAdding = true;
    }

    final isDark = theme.brightness == Brightness.dark;

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
              child: BeityButton(
                text: isArabic ? 'إلغاء' : 'Cancel',
                type: BeityButtonType.outline,
                onPressed: isAdding ? null : () {
                  ref.read(aiSuggestionsProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
              ),
            ),
            AppSpacing.gapMD,
            Expanded(
              flex: 2,
              child: BeityButton(
                text: isArabic ? 'أضف المحدد ($selectedCount)' : 'Add Selected ($selectedCount)',
                onPressed: (selectedCount == 0 || isAdding) ? null : _addSelectedItems,
                isLoading: isAdding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
