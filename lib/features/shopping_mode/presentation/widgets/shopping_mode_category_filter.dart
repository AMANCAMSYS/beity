import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_filter_chips.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class ShoppingModeCategoryFilter extends ConsumerWidget {
  final String homeId;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const ShoppingModeCategoryFilter({
    super.key,
    required this.homeId,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(homeId));

    return categoriesAsync.when(
      data: (categories) {
        final labels = [
          context.translate('all'),
          ...categories.map(
            (c) => c.name == 'Other' ? context.translate('other') : c.name,
          ),
        ];
        final selectedIndex = selectedCategoryId == null
            ? 0
            : categories.indexWhere((c) => c.id == selectedCategoryId) + 1;
        return SawaFilterChips(
          labels: labels,
          selectedIndex: selectedIndex,
          onSelected: (index) {
            onCategorySelected(index == 0 ? null : categories[index - 1].id);
          },
          compact: true,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
