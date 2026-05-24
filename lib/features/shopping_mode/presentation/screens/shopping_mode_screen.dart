import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
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
import '../widgets/shopping_category_group.dart';
import '../widgets/shopping_quick_add_overlay.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/satisfaction_survey_dialog.dart';
import '../../../../core/monitoring/monitoring_service.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
            tooltip: isArabic ? 'بحث' : 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ActionDebouncer.execute(() async => _showExitConfirmation(context, isArabic)),
            tooltip: isArabic ? 'خروج' : 'Exit',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isArabic ? 'بحث في المنتجات...' : 'Search items...',
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
            data: (categories) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(isArabic ? 'الكل' : 'All'),
                    selected: _filterCategoryId == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterCategoryId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name == 'Other' ? (isArabic ? 'أخرى' : 'Other') : cat.name),
                      selected: _filterCategoryId == cat.id,
                      onSelected: (selected) {
                        setState(() {
                          _filterCategoryId = selected ? cat.id : null;
                        });
                      },
                    ),
                  )),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
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
                        ? (isArabic ? 'لا توجد نتائج للبحث' : 'No results found')
                        : _filterCategoryId != null
                            ? (isArabic ? 'لا توجد منتجات في هذا التصنيف' : 'No items in this category')
                            : (isArabic ? 'لا توجد منتجات في القائمة' : 'No items in list'),
                    message: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? (isArabic 
                            ? 'جرب تغيير خيارات التصفية أو مسحها للوصول لما تبحث عنه'
                            : 'Try changing your filters or clear them to find what you are looking for')
                        : (isArabic 
                            ? 'ابدأ بإضافة منتجات للقائمة لتظهر هنا'
                            : 'Start adding items to the list to see them here'),
                    icon: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? Icons.search_off_rounded
                        : Icons.shopping_cart_outlined,
                    actionText: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? (isArabic ? 'مسح الفلاتر' : 'Clear Filters')
                        : null,
                    onActionPressed: _searchQuery.isNotEmpty || _filterCategoryId != null
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
                title: isArabic ? 'عذراً، حدث خطأ' : 'Error occurred',
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: isArabic ? 'إعادة المحاولة' : 'Retry',
                onActionPressed: () => ref.invalidate(shoppingItemsProvider(widget.listId)),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FilledButton(
          onPressed: () => ActionDebouncer.execute(() async => _showExitConfirmation(context, isArabic)),
          child: Text(isArabic ? 'إنهاء التسوق' : 'Done Shopping'),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, bool isArabic) {
    final purchasedCount =
        ref.read(shoppingModePurchasedCountProvider(widget.listId));
    final totalCount =
        ref.read(shoppingModeTotalCountProvider(widget.listId));
    final unpurchasedCount = totalCount - purchasedCount;

    if (unpurchasedCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isArabic ? 'الخروج من وضع التسوق؟' : 'Exit Shopping Mode?'),
          content: Text(isArabic
              ? 'لا يزال لديك $unpurchasedCount عناصر غير مشتراة. هل أنت متأكد من الخروج؟'
              : 'You still have $unpurchasedCount unpurchased items. Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                if (purchasedCount > 0) {
                  _showInventoryTransferDialog(isArabic);
                } else {
                  _exitShoppingMode(isArabic);
                }
              },
              child: Text(isArabic ? 'خروج' : 'Exit'),
            ),
          ],
        ),
      );
    } else {
      if (purchasedCount > 0) {
        _showInventoryTransferDialog(isArabic);
      } else {
        _exitShoppingMode(isArabic);
      }
    }
  }

  Future<void> _exitShoppingMode(bool isArabic) async {
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

  void _showInventoryTransferDialog(bool isArabic) {
    final itemsAsync = ref.read(shoppingItemsProvider(widget.listId));
    final purchasedItems = itemsAsync.when(
      data: (items) => items.where((i) => i.isPurchased).toList(),
      loading: () => [],
      error: (_, __) => [],
    );

    if (purchasedItems.isEmpty) {
      _exitShoppingMode(isArabic);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'إضافة إلى المخزون؟' : 'Add to Inventory?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic
              ? 'هل تريد إضافة ${purchasedItems.length} عنصر مشترى إلى المخزون؟'
              : 'Do you want to add ${purchasedItems.length} purchased items to inventory?'),
            const SizedBox(height: 12),
            ...purchasedItems.take(5).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
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
                            ? (isArabic ? '$qty $unitName' : '$qty $unitName')
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
                isArabic ? 'و ${purchasedItems.length - 5} عناصر أخرى...' : 'and ${purchasedItems.length - 5} more items...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitShoppingMode(isArabic);
            },
            child: Text(isArabic ? 'تخطي' : 'Skip'),
          ),
          FilledButton.icon(
            onPressed: () => ActionDebouncer.execute(() async {
              Navigator.pop(context);
              _transferToInventory(purchasedItems, isArabic);
            }),
            icon: const Icon(Icons.inventory_2),
            label: Text(isArabic ? 'إضافة للمخزون' : 'Add to Inventory'),
          ),
        ],
      ),
    );
  }

  Future<void> _transferToInventory(List<dynamic> purchasedItems, bool isArabic) async {
    final stopwatch = Stopwatch()..start();
    final useCase = ref.read(addPurchasedToInventoryUseCaseProvider);
    int successCount = 0;

    for (final item in purchasedItems) {
      try {
        await useCase.call(
          homeId: widget.homeId,
          name: item.name,
          quantity: item.quantity,
          unitId: item.unitId,
          categoryId: item.categoryId,
        );
        successCount++;
      } catch (e) {
        await MonitoringService().log('Failed to transfer item to inventory: ${item.name} - $e');
      }
    }

    stopwatch.stop();
    await MonitoringService().log(
      'Inventory transfer: $successCount/${purchasedItems.length} items in ${stopwatch.elapsedMilliseconds}ms',
    );

    await _exitShoppingMode(isArabic);

    if (mounted && successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم إضافة $successCount عنصر إلى المخزون' : 'Added $successCount items to inventory'),
          action: SnackBarAction(
            label: isArabic ? 'عرض المخزون' : 'View Inventory',
            onPressed: () => context.push('/inventory'),
          ),
        ),
      );
    }
  }
}
