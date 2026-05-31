import 'package:flutter/material.dart';
import 'package:beity/core/localization/app_localizations.dart';

class ShoppingModeSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ShoppingModeSearchBar({
    super.key,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        autofocus: false,
        decoration: InputDecoration(
          hintText: context.translate('search_items_placeholder'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
