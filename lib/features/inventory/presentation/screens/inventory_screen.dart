import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/category_group_header.dart';
import '../../domain/usecases/delete_inventory_item_usecase.dart';
import '../../domain/usecases/update_inventory_quantity_usecase.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';

class InventoryScreen extends ConsumerWidget {
  final String homeId;

  const InventoryScreen({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider(homeId));
    final groupedItems = ref.watch(groupedInventoryItemsProvider(homeId));
    final categoriesAsync = ref.watch(categoriesProvider(homeId));
    final unitsAsync = ref.watch(unitsProvider(null));

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
        title: const Text('المخزون'),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('خطأ في تحميل المخزون: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(inventoryItemsProvider(homeId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildInventoryList(
              context, ref, groupedItems, categoryNames, unitNames);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/add', extra: homeId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'المخزون فارغ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'أضف المنتجات التي لديك في المنزل لتتبعها بسهولة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push('/inventory/add', extra: homeId),
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج'),
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
    try {
      final useCase = DeleteInventoryItemUseCase(
        ref.read(inventoryRepositoryProvider),
      );
      await useCase(itemId: item.id, homeId: homeId);
      ref.invalidate(inventoryItemsProvider(homeId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف المنتج: $e')),
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
    try {
      final step = _getStep(item.unitId);
      final newQty = item.quantity + (step * direction);

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
          SnackBar(content: Text('خطأ في تحديث الكمية: $e')),
        );
      }
    }
  }

  double _getStep(String? unitId) {
    // TODO: Determine step based on unit type (fractional: 0.5, whole: 1)
    // Will be refined when unit data includes fractional flag
    return 1;
  }
}
