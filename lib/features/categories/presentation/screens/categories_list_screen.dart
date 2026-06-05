import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/categories_provider.dart';
import '../widgets/category_card_widget.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/onboarding/presentation/providers/app_tour_controller.dart';
import 'package:sawa/features/onboarding/presentation/providers/app_tour_target_registry.dart';

class CategoriesListScreen extends ConsumerStatefulWidget {
  final String? homeId;

  const CategoriesListScreen({super.key, this.homeId});

  @override
  ConsumerState<CategoriesListScreen> createState() =>
      _CategoriesListScreenState();
}

class _CategoriesListScreenState extends ConsumerState<CategoriesListScreen> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appTourControllerProvider.notifier).maybeStartCategoriesTour(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(
      (homeId: widget.homeId, type: _selectedType),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('categories')),
        actions: [
          if (widget.homeId != null)
            IconButton(
              key: AppTourTargetRegistry.categoriesAddKey,
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/categories/create', extra: widget.homeId);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Type filter
          SingleChildScrollView(
            key: AppTourTargetRegistry.categoriesFilterKey,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, context.translate('all')),
                const SizedBox(width: 8),
                _buildFilterChip('shopping', context.translate('shopping')),
                const SizedBox(width: 8),
                _buildFilterChip('inventory', context.translate('inventory_filter')),
                const SizedBox(width: 8),
                _buildFilterChip('expense', context.translate('expense')),
              ],
            ),
          ),
          // Categories list
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return SawaEmptyState(
                    title: context.translate('no_categories'),
                    message: context.translate('default_categories_desc'),
                    icon: Icons.category_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryCardWidget(
                      category: category,
                      homeId: widget.homeId,
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => SawaEmptyState(
                title: context.translate('error_occurred'),
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
                onAction: () => ref.invalidate(categoriesByTypeProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
    );
  }
}
