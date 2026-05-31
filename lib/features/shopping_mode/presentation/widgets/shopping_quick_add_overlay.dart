import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/localization/app_localizations.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';

class ShoppingQuickAddOverlay extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;
  final VoidCallback onItemAdded;
  final VoidCallback onClose;

  const ShoppingQuickAddOverlay({
    super.key,
    required this.listId,
    required this.homeId,
    required this.onItemAdded,
    required this.onClose,
  });

  @override
  ConsumerState<ShoppingQuickAddOverlay> createState() =>
      _ShoppingQuickAddOverlayState();
}



class _ShoppingQuickAddOverlayState
    extends ConsumerState<ShoppingQuickAddOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _keepOpen = true;
  List<AutocompleteSuggestion> _suggestions = [];
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateSuggestions(query);
    });
  }

  Future<void> _updateSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final repository = ref.read(shoppingItemRepositoryProvider);
    final suggestions = await repository.getAutocompleteSuggestions(
      homeId: widget.homeId,
      query: query,
      limit: 5,
    );

    setState(() => _suggestions = suggestions);
  }

  Future<void> _addItem(String name) async {
    if (name.trim().isEmpty) return;

    final repository = ref.read(shoppingItemRepositoryProvider);
    await repository.createShoppingItem(
      listId: widget.listId,
      name: name.trim(),
    );

    widget.onItemAdded();
    _controller.clear();
    setState(() => _suggestions = []);

    if (!_keepOpen) {
      widget.onClose();
    }

    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.translate('quick_add'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Text field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: context.translate('item_name_placeholder'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _suggestions = []);
                      },
                    ),
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: _addItem,
                ),
                // Suggestions
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._suggestions.map((suggestion) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(suggestion.name),
                        subtitle: suggestion.unitName != null || suggestion.quantity != 1
                            ? Text(isArabic 
                                ? '${suggestion.quantity == suggestion.quantity.roundToDouble() ? suggestion.quantity.toInt() : suggestion.quantity.toStringAsFixed(1)}${suggestion.unitName != null ? " ${suggestion.unitName}" : ""}'
                                : '${suggestion.quantity == suggestion.quantity.roundToDouble() ? suggestion.quantity.toInt() : suggestion.quantity.toStringAsFixed(1)}${suggestion.unitName != null ? " ${suggestion.unitName}" : ""}')
                            : null,
                        onTap: () => _addItem(suggestion.name),
                      )),
                ],
                const SizedBox(height: 16),
                // Keep open toggle
                Row(
                  children: [
                    Checkbox(
                      value: _keepOpen,
                      onChanged: (value) =>
                          setState(() => _keepOpen = value ?? true),
                    ),
                    Text(context.translate('add_another')),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _addItem(_controller.text),
                      child: Text(context.translate('add')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
