import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/app/router/shopping_route_paths.dart';
import 'package:sawa/core/services/notification_service.dart';
import 'package:sawa/core/services/app_logger.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_skeleton_list.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:sawa/core/services/local_cache_notifier.dart';
import 'package:sawa/shared/widgets/purchase_notification_overlay.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import '../../presentation/providers/shopping_mode_provider.dart';
import '../../presentation/providers/shopping_mode_items_provider.dart';
import '../../presentation/providers/shopping_mode_session_provider.dart';
import '../../data/services/shopping_mode_session_recovery_service.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/domain/usecases/mark_item_purchased_usecase.dart';
import '../../../shopping_lists/domain/usecases/update_item_purchase_state_usecase.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../widgets/shopping_progress_bar.dart';
import '../widgets/shopping_quick_add_overlay.dart';
import '../widgets/shopping_guide_dialog.dart';
import '../widgets/shopping_mode_search_bar.dart';
import '../widgets/shopping_mode_category_filter.dart';
import '../widgets/shopping_mode_items_list.dart';
import '../widgets/partial_purchase_dialog.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/core/monitoring/monitoring_service.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'widgets/shopping_mode_exit_handler.dart';

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
  StreamSubscription? _cacheSubscription;
  ShoppingModeExitHandler? _exitHandler;

  ({String listId, String homeId}) get _itemsProviderParams =>
      (listId: widget.listId, homeId: widget.homeId);

  @override
  void initState() {
    super.initState();
    _startSession();
    NotificationService.addActiveScreenSubscription(
      ShoppingRoutePaths.detail(widget.listId),
    );

    try {
      final keepScreenOn = ref.read(appSettingsProvider).keepScreenOn;
      if (keepScreenOn) {
        WakelockPlus.enable();
      }
    } catch (e) {
      AppLogger.i('Wakelock enable failed: $e');
      MonitoringService().log('Wakelock enable failed: $e');
    }

    _cacheSubscription = LocalCacheNotifier.stream.listen((event) {
      if (event.isPurchaseEvent && event.listId == widget.listId && mounted) {
        PurchaseNotificationOverlay.show(
          context,
          itemName: event.itemName!,
          purchaserName: event.purchaserId,
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

    unawaited(MonitoringService().breadcrumbShoppingModeStart(widget.listId));

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
    } catch (e, s) {
      MonitoringService().logError(
        e,
        s,
        reason: 'Partial purchase failed for item ${originalItem.id}',
      );
    }

    if (!mounted) return;
    ref.invalidate(shoppingItemsForHomeProvider(_itemsProviderParams));
  }

  @override
  Widget build(BuildContext context) {
    _exitHandler ??= ShoppingModeExitHandler(
      ref: ref,
      context: context,
      listId: widget.listId,
      homeId: widget.homeId,
      itemsProviderParams: _itemsProviderParams,
    );

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

    final unitsAsync = ref.watch(unitsProvider(null));
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.symbol;
      }
    });

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
              () async => _exitHandler!.showExitConfirmation(),
            ),
            tooltip: context.translate('exit'),
          ),
        ],
      ),
      body: Column(
        children: [
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
          if (_isSearchVisible)
            ShoppingModeSearchBar(
              controller: _searchController,
              searchQuery: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ShoppingModeCategoryFilter(
            homeId: widget.homeId,
            selectedCategoryId: _filterCategoryId,
            onCategorySelected: (id) => setState(() => _filterCategoryId = id),
          ),
          Expanded(
            child: groupsAsync.when(
              data: (groups) => ShoppingModeItemsList(
                listId: widget.listId,
                homeId: widget.homeId,
                groups: groups,
                unitNames: unitNames,
                filterCategoryId: _filterCategoryId,
                searchQuery: _searchQuery,
                shoppingMode: shoppingMode,
                hapticsEnabled: settings.hapticFeedback,
                onToggleCategory: () => ref
                    .read(shoppingModeProvider.notifier)
                    .toggleCategory(_filterCategoryId ?? 'uncategorized'),
                onItemTap: (itemId, isPurchased) =>
                    _togglePurchased(itemId, isPurchased),
                onQuantityTap: (itemId) => _handleQuantityTap(itemId),
                onRetry: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _filterCategoryId = null;
                  });
                },
              ),
              loading: () => const SawaSkeletonList(itemCount: 8),
              error: (error, stack) => SawaEmptyState(
                title: context.translate('error_title'),
                message: context.translate('error_loading_lists_message'),
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
      floatingActionButton: Semantics(
        label: context.translate('add_item'),
        button: true,
        child: FloatingActionButton(
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
          tooltip: context.translate('add_item'),
          child: const Icon(Icons.add),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Semantics(
            label: context.translate('done_shopping'),
            button: true,
            child: SawaButton(
              onPressed: () => ActionDebouncer.execute(
                () async => _exitHandler!.showExitConfirmation(),
              ),
              text: context.translate('done_shopping'),
              fullWidth: true,
            ),
          ),
        ),
      ),
    );
  }
}
