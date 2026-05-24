import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_suggestions_provider.dart';
import '../../domain/entities/ai_suggestion.dart';

class AiSuggestionTile extends ConsumerWidget {
  final int index;
  final AiSuggestion suggestion;
  final List<String> existingItemNames;

  const AiSuggestionTile({
    super.key,
    required this.index,
    required this.suggestion,
    required this.existingItemNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiSuggestionsProvider);
    final isSelected = state is AiSuggestionsSuccess && state.selectedIndices.contains(index);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Duplicate detection (case-insensitive, trimmed match)
    final suggestionNameClean = suggestion.name.trim().toLowerCase();
    final isDuplicate = existingItemNames.any((name) => name.trim().toLowerCase() == suggestionNameClean);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          ref.read(aiSuggestionsProvider.notifier).toggleSelection(index);
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                suggestion.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (isDuplicate)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isArabic ? 'موجود بالفعل' : 'Already in list',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade900),
                ),
              ),
          ],
        ),
        subtitle: _buildSubtitle(context, isArabic),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context, bool isArabic) {
    final infoParts = <Widget>[];
    
    if (suggestion.quantity != null && suggestion.quantity! != 1.0) {
      infoParts.add(Text('${suggestion.quantity}'));
    }
    
    if (suggestion.unit != null && suggestion.unit!.isNotEmpty) {
      if (infoParts.isNotEmpty) infoParts.add(const SizedBox(width: 4));
      infoParts.add(Text(suggestion.unit!));
    }

    if (suggestion.category != null && suggestion.category!.isNotEmpty) {
      if (infoParts.isNotEmpty) {
        infoParts.add(const SizedBox(width: 8));
        infoParts.add(const Text('•'));
        infoParts.add(const SizedBox(width: 8));
      }
      infoParts.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            suggestion.category!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        )
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (infoParts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: infoParts,
            ),
          ),
        if (suggestion.reason != null && suggestion.reason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              suggestion.reason!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
