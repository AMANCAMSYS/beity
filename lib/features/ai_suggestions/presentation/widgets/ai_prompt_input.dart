import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../providers/ai_suggestions_provider.dart';
import '../../domain/entities/ai_suggestion_request.dart';
import '../../../../core/utils/action_debouncer.dart';

class AiPromptInput extends ConsumerStatefulWidget {
  final String listTitle;
  final String homeType;
  final List<String> existingItemNames;

  const AiPromptInput({
    super.key,
    required this.listTitle,
    required this.homeType,
    required this.existingItemNames,
  });

  @override
  ConsumerState<AiPromptInput> createState() => _AiPromptInputState();
}

class _AiPromptInputState extends ConsumerState<AiPromptInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Check loading state
    final state = ref.read(aiSuggestionsProvider);
    if (state is AiSuggestionsLoading || state is AiSuggestionsAdding) return;

    final locale = Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';

    ActionDebouncer.execute(() async {
      FocusScope.of(context).unfocus();
      final request = AiSuggestionRequest(
        prompt: text,
        homeType: widget.homeType,
        listTitle: widget.listTitle,
        existingItems: widget.existingItemNames,
        language: locale,
      );
      ref.read(aiSuggestionsProvider.notifier).fetchSuggestions(request);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSuggestionsProvider);
    final isLoading = state is AiSuggestionsLoading || state is AiSuggestionsAdding;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: context.translate('ai_prompt_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  counterText: "",
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isLoading ? null : _submit,
              icon: isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
