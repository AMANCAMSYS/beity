import 'package:flutter/material.dart';
import '../providers/shopping_items_provider.dart';

class ItemSuggestionsWidget extends StatelessWidget {
  final List<AutocompleteSuggestion> suggestions;
  final String query;
  final ValueChanged<AutocompleteSuggestion> onSuggestionTap;

  const ItemSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.query,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final filtered = suggestions
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final suggestion = filtered[index];
          return ListTile(
            dense: true,
            title: _buildHighlightedText(suggestion.name, query),
            subtitle: _buildSubtitle(suggestion),
            leading: Icon(
              suggestion.isTemplate ? Icons.bookmark_outline : Icons.history,
              size: 20,
            ),
            onTap: () => onSuggestionTap(suggestion),
          );
        },
      ),
    );
  }

  Widget? _buildSubtitle(AutocompleteSuggestion suggestion) {
    final parts = <String>[];
    if (suggestion.quantity != 1) {
      parts.add(suggestion.quantity.toStringAsFixed(
          suggestion.quantity == suggestion.quantity.roundToDouble() ? 0 : 1));
    }
    if (suggestion.unitName != null && suggestion.unitName!.isNotEmpty) {
      parts.add(suggestion.unitName!);
    }
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' '),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(text);
    }

    return RichText(
      text: TextSpan(
        text: text.substring(0, startIndex),
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text: text.substring(startIndex, startIndex + query.length),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(startIndex + query.length),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
