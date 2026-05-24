import 'package:flutter/material.dart';

class CategoryFilterWidget extends StatelessWidget {
  final List<dynamic> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            context,
            label: isArabic ? 'الكل' : 'All',
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),
          ...categories.map((category) => _buildFilterChip(
                context,
                label: category.name,
                isSelected: selectedCategoryId == category.id,
                onTap: () => onCategorySelected(category.id),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
