import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/category_group_header.dart';
import '../widgets/inventory_quick_add_sheet.dart';
import '../../domain/usecases/delete_inventory_item_usecase.dart';
import '../../domain/usecases/update_inventory_quantity_usecase.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../home/presentation/widgets/app_drawer.dart';

class InventoryScreen extends ConsumerWidget {
  final String homeId;

  const InventoryScreen({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider(homeId));
    final groupedItems = ref.watch(groupedInventoryItemsProvider(homeId));
    final categoriesAsync = ref.watch(categoriesProvider(homeId));
    final unitsAsync = ref.watch(unitsProvider(null));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    // Build category name map
    final categoryNames = <String, String>{};
    categoriesAsync.whenData((cats) {
      for (final cat in cats) {
        categoryNames[cat.id] = cat.name;
      }
    });

    // Build unit name map
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.name;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'المخزون' : 'Inventory', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => BeityEmptyState(
          title: isArabic ? 'عذراً، حدث خطأ' : 'Oops, something went wrong',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
          onAction: () => ref.invalidate(inventoryItemsProvider(homeId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return BeityEmptyState(
              title: isArabic ? 'المخزون فارغ' : 'Inventory is empty',
              message: isArabic 
                  ? 'أضف المنتجات التي لديك في المنزل لتتبعها بسهولة وتعرف متى تنفذ' 
                  : 'Add products you have at home to track them easily and know when they run out',
              icon: Icons.inventory_2_rounded,
              actionText: isArabic ? 'إضافة أول منتج' : 'Add First Product',
              onAction: () => context.push('/inventory/add', extra: homeId),
            );
          }
          return _buildInventoryList(
              context, ref, groupedItems, categoryNames, unitNames);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Quick add button
            FloatingActionButton.small(
              heroTag: 'quick_add',
              onPressed: () => _showQuickAdd(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.bolt_rounded),
            ),
            AppSpacing.gapSM,
            // Full add button
            FloatingActionButton(
              heroTag: 'full_add',
              onPressed: () => context.push('/inventory/add', extra: homeId),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInventoryList(
    BuildContext context,
    WidgetRef ref,
    Map<String?, List<InventoryItemModel>> groupedItems,
    Map<String, String> categoryNames,
    Map<String, String> unitNames,
  ) {
    final categoryKeys = groupedItems.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: categoryKeys.fold<int>(
          0, (sum, key) => sum + 1 + (groupedItems[key]?.length ?? 0)),
      itemBuilder: (context, index) {
        var currentIndex = 0;
        for (final categoryId in categoryKeys) {
          final items = groupedItems[categoryId] ?? [];
          if (currentIndex == index) {
            return CategoryGroupHeader(
              categoryName:
                  categoryId != null ? categoryNames[categoryId] : null,
              itemCount: items.length,
            );
          }
          currentIndex++;

          for (final item in items) {
            if (currentIndex == index) {
              return InventoryItemTile(
                item: item,
                unitName: item.unitId != null ? unitNames[item.unitId] : null,
                onTap: () => context.push(
                  '/inventory/${item.id}',
                  extra: {'homeId': homeId},
                ),
                onDelete: () => _deleteItem(context, ref, item),
                onQuantityIncrement: () =>
                    _adjustQuantity(context, ref, item, 1),
                onQuantityDecrement: () =>
                    _adjustQuantity(context, ref, item, -1),
              );
            }
            currentIndex++;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel item,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final useCase = DeleteInventoryItemUseCase(
        ref.read(inventoryRepositoryProvider),
      );
      await useCase(itemId: item.id, homeId: homeId);
      ref.invalidate(inventoryItemsProvider(homeId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'خطأ في حذف المنتج: $e' : 'Error deleting item: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _adjustQuantity(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel item,
    double direction,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final step = _getStep(item.unitId);
      final newQty = item.quantity + (step * direction);
      if (newQty < 0) return;

      final useCase = UpdateInventoryQuantityUseCase(
        ref.read(inventoryRepositoryProvider),
      );
      await useCase(
        itemId: item.id,
        homeId: homeId,
        newQuantity: newQty,
      );
      ref.invalidate(inventoryItemsProvider(homeId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'خطأ في تحديث الكمية: $e' : 'Error updating quantity: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _getStep(String? unitId) {
    // TODO: Determine step based on unit type (fractional: 0.5, whole: 1)
    return 1;
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryQuickAddSheet(
        homeId: homeId,
        onItemAdded: () {
          // Refresh is handled inside the sheet
        },
      ),
    );
  }
}
