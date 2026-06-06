import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_loading_state.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/category_group_header.dart';
import '../widgets/inventory_quick_add_sheet.dart';
import '../../domain/usecases/delete_inventory_item_usecase.dart';
import '../../domain/usecases/update_inventory_quantity_usecase.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import '../../../onboarding/presentation/providers/app_tour_controller.dart';
import '../../../onboarding/presentation/providers/app_tour_target_registry.dart';
import '../../../../core/providers/permissions_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  final String homeId;

  const InventoryScreen({super.key, required this.homeId});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _showOnlyLowStock = false;

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider(widget.homeId));
    final groupedItems = ref.watch(
      groupedInventoryItemsProvider(widget.homeId),
    );
    final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));
    final unitsAsync = ref.watch(unitsProvider(null));
    final theme = Theme.of(context);
    final permissions = ref.watch(
      currentHomePermissionsProvider(widget.homeId),
    );
    final canManage = permissions.canEdit;

    // Trigger the tour after the build is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appTourControllerProvider.notifier)
          .maybeStartInventoryTour(context);
    });

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
        title: Text(
          context.translate('inventory'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: inventoryAsync.when(
        loading: () =>
            SawaLoadingState(message: context.translate('loading_inventory')),
        error: (error, _) => SawaEmptyState(
          title: context.translate('error_occurred'),
          message: ErrorFormatter.format(error, context),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(inventoryItemsProvider(widget.homeId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return SawaEmptyState(
              title: context.translate('inventory_empty'),
              message: context.translate('inventory_empty_desc'),
              icon: Icons.inventory_2_rounded,
              actionText: canManage
                  ? context.translate('add_first_product')
                  : null,
              onAction: canManage
                  ? () => context.push('/inventory/add', extra: widget.homeId)
                  : null,
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: SegmentedButton<bool>(
                  key: AppTourTargetRegistry.inventoryFilterKey,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: Text(context.translate('all')),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: Text(context.translate('low_stock')),
                    ),
                  ],
                  selected: {_showOnlyLowStock},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() {
                      _showOnlyLowStock = selection.first;
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildInventoryList(
                  context,
                  ref,
                  groupedItems,
                  categoryNames,
                  unitNames,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: canManage
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quick add button
                  FloatingActionButton.small(
                    key: AppTourTargetRegistry.inventoryAddKey,
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
                    onPressed: () =>
                        context.push('/inventory/add', extra: widget.homeId),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    elevation: 4,
                    child: const Icon(Icons.add_rounded, size: 28),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    WidgetRef ref,
    Map<String?, List<InventoryItemModel>> groupedItems,
    Map<String, String> categoryNames,
    Map<String, String> unitNames,
  ) {
    final permissions = ref.watch(
      currentHomePermissionsProvider(widget.homeId),
    );
    final canManage = permissions.canEdit;

    // Apply low stock filter if _showOnlyLowStock is true
    final filteredGroupedItems = <String?, List<InventoryItemModel>>{};
    groupedItems.forEach((catId, list) {
      final filteredList = _showOnlyLowStock
          ? list.where((item) => item.isLowStock).toList()
          : list;
      if (filteredList.isNotEmpty) {
        filteredGroupedItems[catId] = filteredList;
      }
    });

    if (filteredGroupedItems.isEmpty) {
      return SawaEmptyState(
        title: context.translate('no_matching_items'),
        message: _showOnlyLowStock
            ? context.translate('no_low_stock_desc')
            : context.translate('inventory_empty_desc'),
        icon: Icons.check_circle_outline_rounded,
        actionText: _showOnlyLowStock ? context.translate('show_all') : null,
        onAction: _showOnlyLowStock
            ? () => setState(() => _showOnlyLowStock = false)
            : null,
      );
    }

    final categoryKeys = filteredGroupedItems.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: categoryKeys.fold<int>(
        0,
        (sum, key) => sum + 1 + (filteredGroupedItems[key]?.length ?? 0),
      ),
      itemBuilder: (context, index) {
        var currentIndex = 0;
        for (final categoryId in categoryKeys) {
          final items = filteredGroupedItems[categoryId] ?? [];
          if (currentIndex == index) {
            return CategoryGroupHeader(
              categoryName: categoryId != null
                  ? categoryNames[categoryId]
                  : null,
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
                  extra: {'homeId': widget.homeId},
                ),
                onDelete: canManage
                    ? () => _deleteItem(context, ref, item)
                    : null,
                onQuantityIncrement: canManage
                    ? () => _adjustQuantity(
                        context,
                        ref,
                        item,
                        1,
                        item.unitId != null ? unitNames[item.unitId] : null,
                      )
                    : null,
                onQuantityDecrement: canManage
                    ? () => _adjustQuantity(
                        context,
                        ref,
                        item,
                        -1,
                        item.unitId != null ? unitNames[item.unitId] : null,
                      )
                    : null,
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
      await useCase(itemId: item.id, homeId: widget.homeId);
      ref.invalidate(inventoryItemsProvider(widget.homeId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate(
                'error_delete_item',
                arguments: {'error': ErrorFormatter.format(e, context)},
              ),
            ),
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
    String? unitName,
  ) async {
    try {
      final step = _getStep(unitName);
      final newQty = item.quantity + (step * direction);
      if (newQty < 0) return;

      final useCase = UpdateInventoryQuantityUseCase(
        ref.read(inventoryRepositoryProvider),
      );
      await useCase(
        itemId: item.id,
        homeId: widget.homeId,
        newQuantity: newQty,
      );
      ref.invalidate(inventoryItemsProvider(widget.homeId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate(
                'error_update_quantity',
                arguments: {'error': ErrorFormatter.format(e, context)},
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _getStep(String? unitName) {
    if (unitName == null) return 1.0;
    final lowerUnit = unitName.toLowerCase();
    if (lowerUnit.contains('kg') ||
        lowerUnit.contains('كجم') ||
        lowerUnit.contains('كيلو') ||
        lowerUnit.contains('kilo') ||
        lowerUnit.contains('g') ||
        lowerUnit.contains('جرام') ||
        lowerUnit.contains('gram') ||
        lowerUnit.contains('liter') ||
        lowerUnit.contains('litre') ||
        lowerUnit.contains('لتر') ||
        lowerUnit.contains('ltr')) {
      return 0.25;
    }
    return 1.0;
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryQuickAddSheet(
        homeId: widget.homeId,
        onItemAdded: () {
          // Refresh is handled inside the sheet
        },
      ),
    );
  }
}
