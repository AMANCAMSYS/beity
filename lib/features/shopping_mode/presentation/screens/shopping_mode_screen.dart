import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/shared/widgets/design_system/beity_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../presentation/providers/shopping_mode_provider.dart';
import '../../presentation/providers/shopping_mode_items_provider.dart';
import '../../presentation/providers/shopping_mode_session_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../shopping_lists/domain/usecases/mark_item_purchased_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/usecases/add_purchased_to_inventory_usecase.dart';
import '../widgets/shopping_category_group.dart';
import '../widgets/shopping_progress_bar.dart';
import '../widgets/shopping_quick_add_overlay.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/satisfaction_survey_dialog.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import 'package:beity/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ShoppingModeScreen extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;
  final String listName;

  const ShoppingModeScreen({
    super.key,
    required this.listId,
    required this.homeId,
    required this.listName,
  });

  @override
  ConsumerState<ShoppingModeScreen> createState() =>
      _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends ConsumerState<ShoppingModeScreen> {
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategoryId;

  @override
  void initState() {
    super.initState();
    _startSession();
    
    // Request screen wake lock if setting is enabled to prevent sleep during shopping
    try {
      final keepScreenOn = ref.read(appSettingsProvider).keepScreenOn;
      if (keepScreenOn) {
        WakelockPlus.enable();
      }
    } catch (e) {
      debugPrint('Wakelock enable failed: $e');
      MonitoringService().log('Wakelock enable failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Safely disable wake lock when leaving shopping mode to restore normal battery saving
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock disable failed: $e');
      MonitoringService().log('Wakelock disable failed: $e');
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return;

    final itemsAsync = ref.read(shoppingItemsProvider(widget.listId));
    final totalItems = itemsAsync.when(
      data: (items) => items.length,
      loading: () => 0,
      error: (error, stack) => 0,
    );

    final useCase = ref.read(startShoppingSessionUseCaseProvider);
    final session = await useCase.call(
      listId: widget.listId,
      userId: currentUser.id,
      homeId: widget.homeId,
      itemsTotalCount: totalItems,
    );

    ref.read(shoppingModeProvider.notifier).activate(session.id);
  }

  Future<void> _togglePurchased(String itemId) async {
    final itemsAsync = ref.read(shoppingItemsProvider(widget.listId));
    final items = itemsAsync.valueOrNull ?? [];
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;

    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = MarkItemPurchasedUseCase(repository);
    await useCase.call(
      itemId: itemId,
      isPurchased: !item.isPurchased,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shoppingMode = ref.watch(shoppingModeProvider);
    final groupsAsync =
        ref.watch(shoppingModeItemsProvider((listId: widget.listId, homeId: widget.homeId)));

    // Load units for display
    final unitsAsync = ref.watch(unitsProvider(null));
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.symbol;
      }
    });

    // Load categories for filter
    final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            tooltip: context.translate('search'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ActionDebouncer.execute(() async => _showExitConfirmation(context)),
            tooltip: context.translate('exit'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar (sticky)
          ShoppingProgressBar(
            purchasedCount: ref.watch(shoppingModePurchasedCountProvider(widget.listId)),
            totalCount: ref.watch(shoppingModeTotalCountProvider(widget.listId)),
          ),
          // Search bar
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.translate('search_items_placeholder'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                autofocus: true,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
          // Category filter chips
          categoriesAsync.when(
            data: (categories) {
              final labels = [
                context.translate('all'),
                ...categories.map((c) => c.name == 'Other' ? context.translate('other') : c.name),
              ];
              final selectedIndex = _filterCategoryId == null
                  ? 0
                  : categories.indexWhere((c) => c.id == _filterCategoryId) + 1;
              return BeityFilterChips(
                labels: labels,
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  setState(() {
                    _filterCategoryId = index == 0 ? null : categories[index - 1].id;
                  });
                },
                compact: true,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          // Items list
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                // Apply filters
                var filteredGroups = groups;
                
                // Filter by category
                if (_filterCategoryId != null) {
                  filteredGroups = groups
                      .where((g) => g.categoryId == _filterCategoryId)
                      .toList();
                }
                
                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filteredGroups = filteredGroups.map((group) {
                    final filteredItems = group.items
                        .where((item) => item.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();
                    return CategoryGroup(
                      categoryId: group.categoryId,
                      categoryName: group.categoryName,
                      items: filteredItems,
                      allPurchased: filteredItems.every((i) => i.isPurchased),
                    );
                  }).where((g) => g.items.isNotEmpty).toList();
                }

                if (filteredGroups.isEmpty) {
                  return BeityEmptyState(
                    title: _searchQuery.isNotEmpty
                        ? context.translate('no_results_found')
                        : _filterCategoryId != null
                            ? context.translate('no_items_in_category')
                            : context.translate('no_items_in_list'),
                    message: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? context.translate('filter_msg_adjust')
                        : context.translate('filter_msg_empty'),
                    icon: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? Icons.search_off_rounded
                        : Icons.shopping_cart_outlined,
                    actionText: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? context.translate('clear_filters')
                        : null,
                    onAction: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                              _filterCategoryId = null;
                            });
                          }
                        : null,
                  );
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    final isCollapsed =
                        shoppingMode.collapsedCategories.contains(group.categoryId) ||
                            group.allPurchased;

                    return ShoppingCategoryGroup(
                      group: group,
                      unitNames: unitNames,
                      isCollapsed: isCollapsed,
                      onToggle: () => ActionDebouncer.execute(() async => ref
                          .read(shoppingModeProvider.notifier)
                          .toggleCategory(group.categoryId ?? 'uncategorized')),
                      onItemTap: (itemId) => ActionDebouncer.execute(() async => _togglePurchased(itemId)),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => BeityEmptyState(
                title: context.translate('error_title'),
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
                onAction: () => ref.invalidate(shoppingItemsProvider(widget.listId)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ActionDebouncer.execute(() async {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ShoppingQuickAddOverlay(
              listId: widget.listId,
              homeId: widget.homeId,
              onItemAdded: () {
                ref.invalidate(shoppingItemsProvider(widget.listId));
                ref.invalidate(shoppingModeItemsProvider((listId: widget.listId, homeId: widget.homeId)));
              },
              onClose: () => Navigator.pop(context),
            ),
          );
        }),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: () => ActionDebouncer.execute(() async => _showExitConfirmation(context)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(context.translate('done_shopping')),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final purchasedCount =
        ref.read(shoppingModePurchasedCountProvider(widget.listId));
    final totalCount =
        ref.read(shoppingModeTotalCountProvider(widget.listId));
    final unpurchasedCount = totalCount - purchasedCount;

    if (unpurchasedCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.translate('exit_shopping_mode_question')),
          content: Text(context.translate('exit_shopping_mode_warning', arguments: {
            'count': unpurchasedCount.toString(),
          })),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.translate('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                if (purchasedCount > 0) {
                  _showInventoryTransferDialog();
                } else {
                  _exitShoppingMode();
                }
              },
              child: Text(context.translate('exit')),
            ),
          ],
        ),
      );
    } else {
      if (purchasedCount > 0) {
        _showInventoryTransferDialog();
      } else {
        _exitShoppingMode();
      }
    }
  }

  Future<void> _exitShoppingMode() async {
    final stopwatch = Stopwatch()..start();
    
    final shoppingMode = ref.read(shoppingModeProvider);
    if (shoppingMode.sessionId != null) {
      final purchasedCount =
          ref.read(shoppingModePurchasedCountProvider(widget.listId));
      final useCase = ref.read(endShoppingSessionUseCaseProvider);
      await useCase.call(
        sessionId: shoppingMode.sessionId!,
        itemsPurchasedCount: purchasedCount,
      );
    }

    ref.read(shoppingModeProvider.notifier).deactivate();
    
    // Log performance
    stopwatch.stop();
    await MonitoringService().log(
      'Shopping mode exit took ${stopwatch.elapsedMilliseconds}ms',
    );

    if (mounted) {
      Navigator.pop(context);
      
      // Show satisfaction survey for beta users
      if (BetaConfig.isBeta) {
        await SatisfactionSurveyDialog.showIfNeeded(context);
      }
    }
  }

  void _showInventoryTransferDialog() {
    final itemsAsync = ref.read(shoppingItemsProvider(widget.listId));
    final purchasedItems = itemsAsync.when(
      data: (items) => items.where((i) => i.isPurchased).toList(),
      loading: () => <ShoppingItemModel>[],
      error: (e, s) => <ShoppingItemModel>[],
    );

    if (purchasedItems.isEmpty) {
      _exitShoppingMode();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('add_to_inventory_question')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.translate('add_to_inventory_msg', arguments: {
              'count': purchasedItems.length.toString(),
            })),
            const SizedBox(height: 12),
            ...purchasedItems.take(5).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final unitsAsync = ref.watch(unitsProvider(null));
                        final units = unitsAsync.valueOrNull ?? [];
                        final unit = units.where((u) => u.id == item.unitId).firstOrNull;
                        final unitName = unit?.symbol;
                        
                        final qty = item.quantity == item.quantity.roundToDouble() 
                            ? item.quantity.toInt().toString() 
                            : item.quantity.toStringAsFixed(1);
                        
                        final displayQty = unitName != null && unitName.isNotEmpty 
                            ? '$qty $unitName'
                            : qty;
                            
                        return Text('${item.name} ($displayQty)');
                      },
                    ),
                  ),
                ],
              ),
            )),
            if (purchasedItems.length > 5)
              Text(
                context.translate('and_more_items', arguments: {
                  'count': (purchasedItems.length - 5).toString(),
                }),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitShoppingMode();
            },
            child: Text(context.translate('skip')),
          ),
          FilledButton.icon(
            onPressed: () => ActionDebouncer.execute(() async {
              Navigator.pop(context);
              _transferToInventory(purchasedItems);
            }),
            icon: const Icon(Icons.inventory_2),
            label: Text(context.translate('add_to_inventory')),
          ),
        ],
      ),
    );
  }

  Future<void> _transferToInventory(List<ShoppingItemModel> purchasedItems) async {
    final stopwatch = Stopwatch()..start();
    
    // Show a loading dialog during transfer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final useCase = ref.read(addPurchasedToInventoryUseCaseProvider);
    int successCount = 0;

    try {
      final inputs = purchasedItems.map((item) => PurchasedItemInput(
        name: item.name,
        quantity: item.quantity,
        unitId: item.unitId,
        categoryId: item.categoryId,
      )).toList();

      await useCase.callBatch(
        homeId: widget.homeId,
        items: inputs,
      );
      successCount = purchasedItems.length;
    } catch (e) {
      await MonitoringService().log('Failed to transfer batch of items to inventory: $e');
    }

    stopwatch.stop();
    await MonitoringService().log(
      'Inventory transfer: $successCount/${purchasedItems.length} items in ${stopwatch.elapsedMilliseconds}ms',
    );

    if (mounted) {
      Navigator.pop(context); // Dismiss the loading dialog
    }

    await _exitShoppingMode();

    if (mounted && successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('added_to_inventory_success', arguments: {
            'count': successCount.toString(),
          })),
          action: SnackBarAction(
            label: context.translate('view_inventory'),
            onPressed: () => context.push('/inventory'),
          ),
        ),
      );
    }
  }
}
