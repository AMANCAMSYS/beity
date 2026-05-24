import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/categories_provider.dart';
import '../widgets/category_card_widget.dart';

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
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(
      (homeId: widget.homeId, type: _selectedType),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التصنيفات',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          if (widget.homeId != null)
            IconButton(
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
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, 'الكل'),
                const SizedBox(width: 8),
                _buildFilterChip('shopping', 'تسوق'),
                const SizedBox(width: 8),
                _buildFilterChip('inventory', 'مخزون'),
                const SizedBox(width: 8),
                _buildFilterChip('expense', 'مصروفات'),
              ],
            ),
          ),
          // Categories list
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return BeityEmptyState(
                    title: 'لا توجد تصنيفات',
                    message: 'سيتم عرض التصنيفات الافتراضية هنا',
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
              error: (error, stack) => BeityEmptyState(
                title: 'حدث خطأ',
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: 'إعادة المحاولة',
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
