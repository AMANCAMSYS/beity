import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/router/feature_route_paths.dart';
import 'package:sawa/app/router/shopping_route_paths.dart';
import 'package:sawa/core/config/feature_flags.dart';
import 'package:sawa/core/services/notification_service.dart';
import 'package:sawa/core/services/app_logger.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_filter_chips.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:sawa/core/services/local_cache_notifier.dart';
import 'package:sawa/shared/widgets/purchase_notification_overlay.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../presentation/providers/shopping_mode_provider.dart';
import '../../presentation/providers/shopping_mode_items_provider.dart';
import '../../presentation/providers/shopping_mode_session_provider.dart';
import '../../data/services/shopping_mode_session_recovery_service.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/domain/usecases/mark_item_purchased_usecase.dart';
import '../../../shopping_lists/domain/usecases/update_item_purchase_state_usecase.dart';
import '../../../shopping_lists/domain/usecases/complete_list_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/usecases/add_purchased_to_inventory_usecase.dart';
import '../widgets/shopping_category_group.dart';
import '../widgets/shopping_progress_bar.dart';
import '../widgets/shopping_quick_add_overlay.dart';
import '../widgets/shopping_guide_dialog.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/satisfaction_survey_dialog.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/error_formatter.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/partial_purchase_dialog.dart';

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
  ConsumerState<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends ConsumerState<ShoppingModeScreen> {
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategoryId;
  bool _isTransferring = false;
  StreamSubscription? _cacheSubscription;

  ({String listId, String homeId}) get _itemsProviderParams =>
      (listId: widget.listId, homeId: widget.homeId);

  @override
  void initState() {
    super.initState();
    _startSession();
    NotificationService.addActiveScreenSubscription(
      ShoppingRoutePaths.detail(widget.listId),
    );

    // Request screen wake lock if setting is enabled to prevent sleep during shopping
    try {
      final keepScreenOn = ref.read(appSettingsProvider).keepScreenOn;
      if (keepScreenOn) {
        WakelockPlus.enable();
      }
    } catch (e) {
      AppLogger.i('Wakelock enable failed: $e');
      MonitoringService().log('Wakelock enable failed: $e');
    }

    // Listen to real-time purchase updates from other users
    _cacheSubscription = LocalCacheNotifier.stream.listen((event) {
      if (event.isPurchaseEvent && event.listId == widget.listId && mounted) {
        PurchaseNotificationOverlay.show(
          context,
          itemName: event.itemName!,
          purchaserName:
              event.purchaserId, // Could map to user name if we had the map
          isPurchased: event.isPurchased!,
        );
      }
    });
  }

  @override
  void dispose() {
    NotificationService.removeActiveScreenSubscription(
      ShoppingRoutePaths.detail(widget.listId),
    );
    _cacheSubscription?.cancel();
    _searchController.dispose();
    // Safely disable wake lock when leaving shopping mode to restore normal battery saving
    try {
      WakelockPlus.disable();
    } catch (e) {
      AppLogger.i('Wakelock disable failed: $e');
      MonitoringService().log('Wakelock disable failed: $e');
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return;

    int totalItems = 0;
    try {
      final items = await ref.read(
        shoppingItemsForHomeProvider(_itemsProviderParams).future,
      );
      if (!mounted) return;
      totalItems = items.length;
    } catch (e) {
      AppLogger.i('[ShoppingModeScreen] Failed to preload item count: $e');
    }

    try {
      final useCase = ref.read(startShoppingSessionUseCaseProvider);
      final session = await useCase.call(
        listId: widget.listId,
        userId: currentUser.id,
        homeId: widget.homeId,
        itemsTotalCount: totalItems,
      );

      if (!mounted) return;
      ref.read(shoppingModeProvider.notifier).activate(session.id);
      await ref
          .read(shoppingModeSessionRecoveryServiceProvider)
          .markSessionActive(
            sessionId: session.id,
            userId: currentUser.id,
            listId: widget.listId,
            homeId: widget.homeId,
            startedAt: session.startedAt,
          );
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }

  Future<void> _togglePurchased(String itemId, bool isPurchased) async {
    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
      final useCase = MarkItemPurchasedUseCase(repository);
      await useCase.call(itemId: itemId, isPurchased: isPurchased);
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }

  Future<void> _handleQuantityTap(String itemId) async {
    final items = await ref.read(
      shoppingItemsForHomeProvider(_itemsProviderParams).future,
    );
    if (!mounted) return;
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null || item.isPurchased) return;

    final unitsAsync = ref.read(unitsProvider(null));
    final units = unitsAsync.value ?? [];
    final unit = units.where((u) => u.id == item.unitId).firstOrNull;

    final result = await showDialog<double>(
      context: context,
      builder: (context) =>
          PartialPurchaseDialog(item: item, unitName: unit?.symbol),
    );

    if (result != null && result > 0 && mounted) {
      await _processPartialPurchase(item, result);
    }
  }

  Future<void> _processPartialPurchase(
    ShoppingItemModel originalItem,
    double purchasedQuantity,
  ) async {
    final repository = ref.read(
      shoppingItemRepositoryForHomeProvider(widget.homeId),
    );

    try {
      final useCase = UpdateItemPurchaseStateUseCase(repository);
      await useCase(
        itemId: originalItem.id,
        purchasedQuantity: purchasedQuantity,
      );
      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (hapticEnabled) {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Optimistic UI will correct on next provider rebuild
    }

    if (!mounted) return;
    ref.invalidate(shoppingItemsForHomeProvider(_itemsProviderParams));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shoppingMode = ref.watch(shoppingModeProvider);
    final settings = ref.watch(appSettingsProvider);
    final listAsync = ref.watch(
      shoppingListByIdForHomeProvider((
        listId: widget.listId,
        homeId: widget.homeId,
      )),
    );
    final groupsAsync = ref.watch(
      shoppingModeItemsProvider((listId: widget.listId, homeId: widget.homeId)),
    );

    final list = listAsync.value;
    if (list != null &&
        (!list.isActive || list.inventoryTransferredAt != null)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.listName)),
        body: SawaEmptyState(
          title: context.translate('list_not_available_for_shopping'),
          message: context.translate('list_not_available_for_shopping_desc'),
          icon: Icons.task_alt_rounded,
          actionText: context.translate('back'),
          onAction: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      );
    }

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
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => ShoppingGuideDialog.show(context),
            tooltip: context.translate('shopping_guide_title'),
          ),
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
            onPressed: () => ActionDebouncer.execute(
              () async => _showExitConfirmation(context),
            ),
            tooltip: context.translate('exit'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar (sticky)
          ShoppingProgressBar(
            purchasedCount: ref.watch(
              shoppingModePurchasedCountForHomeProvider(_itemsProviderParams),
            ),
            totalCount: ref.watch(
              shoppingModeTotalCountForHomeProvider(_itemsProviderParams),
            ),
            progress: ref.watch(
              shoppingModeProgressForHomeProvider(_itemsProviderParams),
            ),
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
                ...categories.map(
                  (c) =>
                      c.name == 'Other' ? context.translate('other') : c.name,
                ),
              ];
              final selectedIndex = _filterCategoryId == null
                  ? 0
                  : categories.indexWhere((c) => c.id == _filterCategoryId) + 1;
              return SawaFilterChips(
                labels: labels,
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  setState(() {
                    _filterCategoryId = index == 0
                        ? null
                        : categories[index - 1].id;
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
                  filteredGroups = filteredGroups
                      .map((group) {
                        final filteredItems = group.items
                            .where(
                              (item) => item.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();
                        return CategoryGroup(
                          categoryId: group.categoryId,
                          categoryName: group.categoryName,
                          items: filteredItems,
                          allPurchased: filteredItems.every(
                            (i) => i.isPurchased,
                          ),
                        );
                      })
                      .where((g) => g.items.isNotEmpty)
                      .toList();
                }

                if (filteredGroups.isEmpty) {
                  return SawaEmptyState(
                    title: _searchQuery.isNotEmpty
                        ? context.translate('no_results_found')
                        : _filterCategoryId != null
                        ? context.translate('no_items_in_category')
                        : context.translate('no_items_in_list'),
                    message:
                        _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? context.translate('filter_msg_adjust')
                        : context.translate('filter_msg_empty'),
                    icon: _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? Icons.search_off_rounded
                        : Icons.shopping_cart_outlined,
                    actionText:
                        _searchQuery.isNotEmpty || _filterCategoryId != null
                        ? context.translate('clear_filters')
                        : null,
                    onAction:
                        _searchQuery.isNotEmpty || _filterCategoryId != null
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
                    final categoryId = group.categoryId ?? 'uncategorized';

                    final bool isCollapsed = shoppingMode.isCategoryCollapsed(
                      categoryId,
                      fallback: group.allPurchased,
                    );

                    return ShoppingCategoryGroup(
                      key: ValueKey(categoryId),
                      group: group,
                      unitNames: unitNames,
                      isCollapsed: isCollapsed,
                      hapticsEnabled: settings.hapticFeedback,
                      onToggle: () => ActionDebouncer.execute(
                        () async => ref
                            .read(shoppingModeProvider.notifier)
                            .toggleCategory(categoryId),
                      ),
                      onItemTap: (itemId, isPurchased) =>
                          ActionDebouncer.execute(
                            () async => _togglePurchased(itemId, isPurchased),
                          ),
                      onQuantityTap: (itemId) => ActionDebouncer.execute(
                        () async => _handleQuantityTap(itemId),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => SawaEmptyState(
                title: context.translate('error_title'),
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
                onAction: () => ref.invalidate(
                  shoppingItemsForHomeProvider(_itemsProviderParams),
                ),
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
                ref.invalidate(
                  shoppingItemsForHomeProvider(_itemsProviderParams),
                );
                ref.invalidate(
                  shoppingModeItemsProvider((
                    listId: widget.listId,
                    homeId: widget.homeId,
                  )),
                );
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
            onPressed: () => ActionDebouncer.execute(
              () async => _showExitConfirmation(context),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(context.translate('done_shopping')),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final purchasedCount = ref.read(
      shoppingModePurchasedCountForHomeProvider(_itemsProviderParams),
    );
    final totalCount = ref.read(
      shoppingModeTotalCountForHomeProvider(_itemsProviderParams),
    );
    final unpurchasedCount = totalCount - purchasedCount;

    if (unpurchasedCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.translate('exit_shopping_mode_question')),
          content: Text(
            context.translate(
              'exit_shopping_mode_warning',
              arguments: {'count': unpurchasedCount.toString()},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.translate('cancel')),
            ),
            FilledButton(
              onPressed: () => ActionDebouncer.execute(() async {
                Navigator.pop(context);
                if (FeatureFlags.enableInventory && purchasedCount > 0) {
                  await _autoTransferToInventory();
                } else {
                  await _exitShoppingMode();
                }
              }),
              child: Text(context.translate('exit')),
            ),
          ],
        ),
      );
    } else {
      if (FeatureFlags.enableInventory && purchasedCount > 0) {
        _autoTransferToInventory();
      } else {
        _exitShoppingMode();
      }
    }
  }

  Future<void> _exitShoppingMode({
    bool completeList = true,
    bool endSession = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (endSession) {
      try {
        await _endActiveSession();
      } catch (e) {
        await MonitoringService().log('Failed to end shopping session: $e');
        if (!mounted) return;
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        return;
      }
    }

    if (completeList) {
      try {
        final repository = ref.read(
          shoppingListRepositoryForHomeProvider(widget.homeId),
        );
        await CompleteListUseCase(repository).call(listId: widget.listId);
        if (!mounted) return;
        ref.invalidate(shoppingListsProvider(widget.homeId));
      } catch (e) {
        await MonitoringService().log('Failed to complete list: $e');
        if (!mounted) return;
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        return;
      }
    }

    ref.read(shoppingModeProvider.notifier).deactivate();

    final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
    if (hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    // Log performance
    stopwatch.stop();
    await MonitoringService().log(
      'Shopping mode exit took ${stopwatch.elapsedMilliseconds}ms',
    );
    if (!mounted) return;

    if (context.canPop()) {
      context.pop();
    }

    // Show satisfaction survey for beta users
    if (BetaConfig.isBeta && mounted) {
      await SatisfactionSurveyDialog.showIfNeeded(context);
    }
  }

  Future<void> _endActiveSession() async {
    final shoppingMode = ref.read(shoppingModeProvider);
    if (shoppingMode.sessionId == null) return;

    final purchasedCount = ref.read(
      shoppingModePurchasedCountForHomeProvider(_itemsProviderParams),
    );
    final useCase = ref.read(endShoppingSessionUseCaseProvider);
    await useCase.call(
      sessionId: shoppingMode.sessionId!,
      itemsPurchasedCount: purchasedCount,
    );
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser != null) {
      await ref
          .read(shoppingModeSessionRecoveryServiceProvider)
          .clearActiveSession(currentUser.id);
    }
  }

  Future<void> _autoTransferToInventory() async {
    List<ShoppingItemModel> purchasedItems;
    try {
      final items = await ref.read(
        shoppingItemsForHomeProvider(_itemsProviderParams).future,
      );
      purchasedItems = items
          .where((i) => i.isPurchased || i.purchasedQuantity > 0)
          .toList();
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
      return;
    }

    if (purchasedItems.isEmpty) {
      await _exitShoppingMode();
      return;
    }

    if (!mounted) return;
    _showInventoryConfirmDialog(purchasedItems);
  }

  void _showInventoryConfirmDialog(List<ShoppingItemModel> purchasedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('add_to_inventory_question')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate(
                'add_to_inventory_msg',
                arguments: {'count': purchasedItems.length.toString()},
              ),
            ),
            const SizedBox(height: 12),
            ...purchasedItems
                .take(5)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final unitsAsync = ref.watch(unitsProvider(null));
                              final units = unitsAsync.value ?? [];
                              final unit = units
                                  .where((u) => u.id == item.unitId)
                                  .firstOrNull;
                              final unitName = unit?.symbol;

                              final qtyToTransfer = item.purchasedQuantity > 0
                                  ? item.purchasedQuantity
                                  : item.quantity;
                              final qty =
                                  qtyToTransfer == qtyToTransfer.roundToDouble()
                                  ? qtyToTransfer.toInt().toString()
                                  : qtyToTransfer.toStringAsFixed(1);

                              final displayQty =
                                  unitName != null && unitName.isNotEmpty
                                  ? '$qty $unitName'
                                  : qty;

                              return Text('${item.name} ($displayQty)');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (purchasedItems.length > 5)
              Text(
                context.translate(
                  'and_more_items',
                  arguments: {'count': (purchasedItems.length - 5).toString()},
                ),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ActionDebouncer.execute(() async {
              Navigator.pop(context);
              await _exitShoppingMode();
            }),
            child: Text(context.translate('exit')),
          ),
          FilledButton.icon(
            onPressed: () => ActionDebouncer.execute(() async {
              Navigator.pop(context);
              await _transferToInventory(purchasedItems);
            }),
            icon: const Icon(Icons.inventory_2),
            label: Text(context.translate('add_to_inventory')),
          ),
        ],
      ),
    );
  }

  Future<void> _transferToInventory(
    List<ShoppingItemModel> purchasedItems,
  ) async {
    if (_isTransferring) return;
    _isTransferring = true;

    try {
      final stopwatch = Stopwatch()..start();

      // Show a loading dialog during transfer
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final useCase = ref.read(addPurchasedToInventoryUseCaseProvider);
      int successCount = 0;

      try {
        final inputs = purchasedItems
            .map(
              (item) => PurchasedItemInput(
                name: item.name,
                quantity: item.purchasedQuantity > 0
                    ? item.purchasedQuantity
                    : item.quantity,
                unitId: item.unitId,
                categoryId: item.categoryId,
              ),
            )
            .toList();

        await _endActiveSession();
        await useCase.callBatch(
          listId: widget.listId,
          homeId: widget.homeId,
          items: inputs,
        );
        successCount = purchasedItems.length;
      } catch (e) {
        await MonitoringService().log(
          'Failed to transfer batch of items to inventory: $e',
        );
        if (mounted) {
          Navigator.pop(context); // Dismiss the loading dialog
          SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        }
        return; // Stop execution, don't exit shopping mode
      }

      stopwatch.stop();
      await MonitoringService().log(
        'Inventory transfer: $successCount/${purchasedItems.length} items in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (!mounted) return;

      if (mounted) {
        Navigator.pop(context); // Dismiss the loading dialog
      }

      ref.invalidate(shoppingListsProvider(widget.homeId));
      await _exitShoppingMode(completeList: false, endSession: false);

      // Show success message after screen is popped
      if (successCount > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.translate(
                        'added_to_inventory_success',
                        arguments: {'count': successCount.toString()},
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: context.translate('view_inventory'),
                textColor: Colors.white,
                onPressed: () => context.push(FeatureRoutePaths.inventory),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        _isTransferring = false;
      }
    }
  }
}
