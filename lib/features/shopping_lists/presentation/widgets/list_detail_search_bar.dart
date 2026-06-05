import 'package:flutter/material.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class ListDetailSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ListDetailSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.translate('search_items_placeholder'),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: onClear,
                )
              : null,
        ),
        onChanged: onChanged,
        onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );
  }
}
