import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/providers/shopping_mode_provider.dart';
import '../../presentation/providers/shopping_mode_items_provider.dart';
import '../../presentation/providers/shopping_mode_session_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../shopping_lists/domain/usecases/mark_item_purchased_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../widgets/shopping_category_group.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/satisfaction_survey_dialog.dart';
import '../../../../core/accessibility/semantics_helpers.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/error_handling/error_handling_mixin.dart';

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
          Semantics(
            button: true,
            label: 'بحث في المنتجات',
            child: IconButton(
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
            ),
          ),
          Semantics(
            button: true,
            label: 'الخروج من وضع التسوق',
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(context),
            ),
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
                  hintText: 'بحث في المنتجات...',
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
                    label: const Text('الكل'),
                    selected: _filterCategoryId == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterCategoryId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty || _filterCategoryId != null
                              ? Icons.search_off
                              : Icons.shopping_cart_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'لا توجد نتائج للبحث'
                              : _filterCategoryId != null
                                  ? 'لا توجد منتجات في هذا التصنيف'
                                  : 'لا توجد منتجات في القائمة',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _filterCategoryId != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                                _filterCategoryId = null;
                              });
                            },
                            child: const Text('مسح الفلاتر'),
                          ),
                        ],
                      ],
                    ),
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
                      onToggle: () => ref
                          .read(shoppingModeProvider.notifier)
                          .toggleCategory(group.categoryId ?? 'uncategorized'),
                      onItemTap: _togglePurchased,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement quick add overlay
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          button: true,
          label: 'Done Shopping button',
          child: FilledButton(
            onPressed: () => _showExitConfirmation(context),
            child: const Text('Done Shopping'),
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
          title: const Text('Exit Shopping Mode?'),
          content: Text(
              'You still have $unpurchasedCount items unpurchased. Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _exitShoppingMode();
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      );
    } else {
      _exitShoppingMode();
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
}
