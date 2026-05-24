import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_suggestions_provider.dart';
import 'ai_suggestion_tile.dart';
import '../../domain/entities/ai_suggestion.dart';

class AiSuggestionsList extends ConsumerWidget {
  final List<AiSuggestion> suggestions;
  final List<String> existingItemNames;

  const AiSuggestionsList({
    super.key,
    required this.suggestions,
    required this.existingItemNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiSuggestionsProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    int selectedCount = 0;
    if (state is AiSuggestionsSuccess) {
      selectedCount = state.selectedIndices.length;
    }

    final totalCount = suggestions.length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic 
                    ? 'تم تحديد $selectedCount من $totalCount'
                    : '$selectedCount of $totalCount selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => ref.read(aiSuggestionsProvider.notifier).selectAll(),
                      child: Text(isArabic ? 'تحديد الكل' : 'Select All'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(aiSuggestionsProvider.notifier).deselectAll(),
                      child: Text(isArabic ? 'إلغاء التحديد' : 'Deselect All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: ListView.separated(
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return AiSuggestionTile(
                index: index,
                suggestion: suggestions[index],
                existingItemNames: existingItemNames,
              );
            },
          ),
        ),
      ],
    );
  }
}
