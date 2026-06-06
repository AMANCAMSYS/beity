import 'dart:async';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/app/router/shopping_route_paths.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_skeleton_list.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../providers/realtime_providers.dart';
import '../widgets/quick_add_item_bottom_sheet.dart';
import '../../domain/usecases/mark_item_purchased_usecase.dart';
import '../../domain/usecases/update_item_purchase_state_usecase.dart';
import '../../../../shared/widgets/purchase_notification_overlay.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/models/shopping_list_model.dart';
import '../../domain/entities/shopping_item.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../offline_queue/presentation/widgets/connectivity_listener.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../shopping_mode/presentation/widgets/partial_purchase_dialog.dart';
import '../../../shopping_mode/presentation/widgets/shopping_guide_dialog.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/error_formatter.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import 'models/list_detail_item.dart';
import 'widgets/isolated_sync_status_banner.dart';
import 'widgets/isolated_presence_indicator.dart';
import 'widgets/list_items_section.dart';

enum _ListAction { shoppingMode, summary, activity, quickAdd }

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.homeId,
  });

  @override
  ConsumerState<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState
    extends ConsumerState<ShoppingListDetailScreen> {
  ShoppingItem? _lastDeletedItem;
  Timer? _undoTimer;

  bool _isSearchVisible = false;
  final Map<String?, bool> _expandedCategories = {};

  final Map<String, DateTime> _highlightedItems = {};

  bool _firstRenderReported = false;

  StreamSubscription? _cacheSubscription;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategoryId;

  ({String listId, String homeId}) get _itemsProviderParams =>
      (listId: widget.listId, homeId: widget.homeId);

  @override
  void initState() {
    super.initState();
    _joinPresence();
    NotificationService.addActiveScreenSubscription(
      ShoppingRoutePaths.detail(widget.listId),
    );
    MonitoringService().breadcrumbShoppingListOpen(widget.listId);

    _cacheSubscription = LocalCacheNotifier.stream.listen((event) {
      if (event.isPurchaseEvent && event.listId == widget.listId && mounted) {
        final members =
            ref.read(homeMembersProvider(widget.homeId)).value ?? [];
        final purchaserName = members
            .where((m) => m.userId == event.purchaserId)
            .map((m) => m.userName)
            .firstOrNull;

        PurchaseNotificationOverlay.show(
          context,
          itemName: event.itemName!,
          purchaserName: purchaserName,
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
    _scrollController.dispose();
    _undoTimer?.cancel();
    _searchController.dispose();
    _leavePresence();
    super.dispose();
  }

  void _joinPresence() {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final service = ref.read(realtimeServiceProvider);
      if (service.isDisposed) return;
      final channelName = 'presence:list:${widget.listId}';
      service.watchPresence(
        channelName: channelName,
        userPayload: PresencePayload(
          userId: currentUser.id,
          displayName:
              currentUser.userMetadata?['full_name'] as String? ??
              ref.read(appLocalizationsProvider).translate('user'),
          avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
        ),
      );
    } catch (e, s) {
      MonitoringService().logError(
        e,
        s,
        reason: 'Presence join failed for list ${widget.listId}',
      );
    }
  }

  void _leavePresence() {
    try {
      final service = ref.read(realtimeServiceProvider);
      if (!service.isDisposed) {
        final channelName = 'presence:list:${widget.listId}';
        service.leavePresence(channelName: channelName);
      }
    } catch (e, s) {
      MonitoringService().logError(
        e,
        s,
        reason: 'Presence leave failed for list ${widget.listId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(
      shoppingListByIdForHomeProvider((
        listId: widget.listId,
        homeId: widget.homeId,
      )),
    );
    final itemsAsync = ref.watch(
      shoppingItemsForHomeProvider(_itemsProviderParams),
    );
    final list = listAsync.value;
    final homeId = widget.homeId;
    final currentUser = SupabaseService.client.auth.currentUser;

    final unitsAsync = ref.watch(unitsProvider(null));
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.symbol.isNotEmpty
            ? '${unit.name} (${unit.symbol})'
            : unit.name;
      }
    });

    final categoriesAsync = ref.watch(categoriesProvider(homeId));
    final settings = ref.watch(appSettingsProvider.select((s) => s));

    return ConnectivityListener(
      homeId: homeId,
      child: Scaffold(
        appBar: _buildAppBar(context, listAsync, itemsAsync, list),
        body: Column(
          children: [
            IsolatedSyncStatusBanner(homeId: homeId),
            IsolatedPresenceIndicatorWidget(
              listId: widget.listId,
              currentUserId: currentUser?.id ?? '',
            ),
            Expanded(
              child: listAsync.when(
                skipLoadingOnReload: true,
                data: (list) {
                  if (list == null) {
                    return SawaEmptyState(
                      title: context.translate('list_not_found'),
                      message: context.translate('list_not_found_desc'),
                      icon: Icons.error_outline_rounded,
                      isError: true,
                      actionText: context.translate('back_to_lists'),
                      onAction: () => ActionDebouncer.execute(
                        () async => context.go(ShoppingRoutePaths.lists),
                      ),
                    );
                  }

                  if (!_firstRenderReported) {
                    _firstRenderReported = true;
                    MonitoringService().markShoppingListFirstRender();
                  }

                  return itemsAsync.when(
                    skipLoadingOnReload: true,
                    data: (items) {
                      if (items.isEmpty) {
                        return SawaEmptyState(
                          title: context.translate('list_empty'),
                          message: context.translate('list_empty_desc'),
                          icon: Icons.shopping_basket_rounded,
                          actionText: context.translate('add_first_item'),
                          onAction: () => ActionDebouncer.execute(() async {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => QuickAddItemBottomSheet(
                                listId: widget.listId,
                                homeId: homeId,
                              ),
                            );
                          }),
                        );
                      }

                      var filtered = items;
                      if (_searchQuery.isNotEmpty) {
                        filtered = filtered
                            .where(
                              (i) => i.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();
                      }

                      if (_filterCategoryId != null) {
                        filtered = filtered
                            .where((i) => i.categoryId == _filterCategoryId)
                            .toList();
                      }

                      final unpurchasedTotal = items
                          .where((i) => !i.isPurchased && i.price != null)
                          .fold<double>(0, (sum, i) => sum + i.price!);
                      final queueEntriesAsync = ref.watch(
                        queueEntriesProvider(homeId),
                      );
                      final queueEntries = queueEntriesAsync.value ?? [];
                      final pendingIds = queueEntries
                          .where((e) => e.isPending)
                          .map((e) => e.entityId)
                          .toSet();

                      final categories = categoriesAsync.value ?? [];
                      final categoryById = {
                        for (final c in categories) c.id: c,
                      };

                      final flattenedList = _buildFlattenedList(
                        filtered,
                        items,
                        pendingIds,
                        categoryById,
                        settings.groupedByCategory,
                        context,
                      );

                      return ListItemsSection(
                        flattenedList: flattenedList,
                        isSearchVisible: _isSearchVisible,
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        onSearchClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        categories: categories,
                        filterCategoryId: _filterCategoryId,
                        onCategorySelected: (id) {
                          setState(() => _filterCategoryId = id);
                        },
                        listId: widget.listId,
                        homeId: homeId,
                        unpurchasedTotal: unpurchasedTotal,
                        unitNames: unitNames,
                        highlightedItems: _highlightedItems,
                        compactListMode: settings.compactListMode,
                        hapticFeedback: settings.hapticFeedback,
                        soundEffects: settings.soundEffects,
                        onTogglePurchased: (itemId, isPurchased) =>
                            ActionDebouncer.execute(
                              () => _togglePurchased(itemId, isPurchased),
                            ),
                        onQuantityTap: (itemId) => _handleQuantityTap(itemId),
                        onEdit: (item) => ActionDebouncer.execute(
                          () => context.push(
                            ShoppingRoutePaths.editItem(
                              widget.listId,
                              item.id,
                              homeId: widget.homeId,
                            ),
                            extra: {'homeId': widget.homeId},
                          ),
                        ),
                        onDelete: (item) =>
                            ActionDebouncer.execute(() => _deleteItem(item)),
                        onToggleCategory: (categoryId) {
                          setState(() {
                            _expandedCategories[categoryId] =
                                !(_expandedCategories[categoryId] ?? true);
                          });
                        },
                        onClearFilters: () {
                          setState(() {
                            _searchQuery = '';
                            _filterCategoryId = null;
                            _searchController.clear();
                          });
                        },
                      );
                    },
                    loading: () => const SawaSkeletonList(itemCount: 6),
                    error: (error, _) => SawaEmptyState(
                      title: context.translate('load_items_failed'),
                      message: ErrorFormatter.format(error, context),
                      icon: Icons.error_outline_rounded,
                      isError: true,
                      actionText: context.translate('retry'),
                      onAction: () => ref.invalidate(
                        shoppingItemsForHomeProvider(_itemsProviderParams),
                      ),
                    ),
                  );
                },
                loading: () => const SawaSkeletonList(itemCount: 4),
                error: (error, _) => SawaEmptyState(
                  title: context.translate('load_list_failed'),
                  message: ErrorFormatter.format(error, context),
                  icon: Icons.error_outline_rounded,
                  isError: true,
                  actionText: context.translate('retry'),
                  onAction: () => ref.invalidate(
                    shoppingListByIdForHomeProvider((
                      listId: widget.listId,
                      homeId: widget.homeId,
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ListDetailItem> _buildFlattenedList(
    List<ShoppingItemModel> filtered,
    List<ShoppingItemModel> items,
    Set<String> pendingIds,
    Map<String, CategoryModel> categoryById,
    bool groupedByCategory,
    BuildContext context,
  ) {
    final flattenedList = <ListDetailItem>[];

    if (groupedByCategory) {
      final grouped = <String?, List<ShoppingItemModel>>{};
      for (final item in filtered) {
        grouped.putIfAbsent(item.categoryId, () => []).add(item);
      }
      for (final entry in grouped.entries) {
        final categoryId = entry.key;
        final groupItems = entry.value;

        groupItems.sort((a, b) {
          if (a.isPurchased != b.isPurchased) {
            return a.isPurchased ? 1 : -1;
          }
          if (a.isPurchased) {
            final aTime = a.purchasedAt ?? a.updatedAt ?? a.createdAt;
            final bTime = b.purchasedAt ?? b.updatedAt ?? b.createdAt;
            if (aTime != null && bTime != null) {
              return bTime.compareTo(aTime);
            }
            return 0;
          }
          final aPriority = ShoppingItem.priorityOrder(a.priority);
          final bPriority = ShoppingItem.priorityOrder(b.priority);
          if (aPriority != bPriority) {
            return aPriority.compareTo(bPriority);
          }
          return a.name.compareTo(b.name);
        });

        final isExpanded = _expandedCategories[categoryId] ?? true;
        final unpurchasedCount = groupItems.where((i) => !i.isPurchased).length;

        final cat = categoryById[categoryId];
        final categoryName = cat?.name ?? context.translate('uncategorized');

        flattenedList.add(
          CategoryHeaderItem(
            categoryId: categoryId,
            categoryName: categoryName,
            unpurchasedCount: unpurchasedCount,
            isExpanded: isExpanded,
          ),
        );

        if (isExpanded) {
          for (final item in groupItems) {
            final hasPending = pendingIds.contains(item.id);
            flattenedList.add(
              ShoppingItemRow(item: item, hasPending: hasPending),
            );
          }
        }
      }
    } else {
      final sorted = [...filtered]
        ..sort((a, b) {
          if (a.isPurchased == b.isPurchased) return 0;
          return a.isPurchased ? 1 : -1;
        });
      for (final item in sorted) {
        final hasPending = pendingIds.contains(item.id);
        flattenedList.add(ShoppingItemRow(item: item, hasPending: hasPending));
      }
    }

    return flattenedList;
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AsyncValue<ShoppingListModel?> listAsync,
    AsyncValue<List<ShoppingItemModel>> itemsAsync,
    ShoppingListModel? list,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const BackButtonIcon(),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(ShoppingRoutePaths.lists);
          }
        },
        tooltip: context.translate('back'),
      ),
      title: listAsync.when(
        data: (list) => Text(
          list?.name ?? context.translate('shopping_lists'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        loading: () => Text(context.translate('loading')),
        error: (error, stackTrace) => Text(context.translate('error_title')),
      ),
      actions: [
        if (FeatureFlags.enableAi)
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.accent,
            ),
            onPressed: () => ActionDebouncer.execute(() async {
              final list = listAsync.value;
              if (list != null) {
                final existingItemNames =
                    itemsAsync.value?.map((e) => e.name).toList() ?? [];
                context.push(
                  ShoppingRoutePaths.aiSuggestions(widget.listId),
                  extra: {
                    'listId': list.id,
                    'listTitle': list.name,
                    'homeId': list.homeId,
                    'homeType': 'family',
                    'existingItemNames': existingItemNames,
                  },
                );
              }
            }),
            tooltip: context.translate('smart_suggestions'),
          ),
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () => ShoppingGuideDialog.show(context),
          tooltip: context.translate('shopping_guide_title'),
        ),
        IconButton(
          icon: Icon(
            _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
          ),
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
        PopupMenuButton<_ListAction>(
          tooltip: context.translate('more'),
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (action) {
            switch (action) {
              case _ListAction.shoppingMode:
                ActionDebouncer.execute(() async {
                  final list = listAsync.value;
                  if (list != null) {
                    context.push(
                      ShoppingRoutePaths.shoppingMode(widget.listId),
                      extra: {'homeId': list.homeId, 'listName': list.name},
                    );
                  }
                });
                break;
              case _ListAction.summary:
                ActionDebouncer.execute(
                  () => context.push(ShoppingRoutePaths.summary(widget.listId)),
                );
                break;
              case _ListAction.activity:
                ActionDebouncer.execute(
                  () => context.push(
                    ShoppingRoutePaths.activity(widget.listId),
                    extra: {
                      'homeId': list?.homeId ?? '',
                      'listName':
                          list?.name ?? context.translate('shopping_lists'),
                    },
                  ),
                );
                break;
              case _ListAction.quickAdd:
                ActionDebouncer.execute(
                  () => context.push(
                    ShoppingRoutePaths.quickAdd(widget.listId),
                    extra: list?.homeId ?? '',
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _ListAction.shoppingMode,
              child: ListTile(
                leading: const Icon(Icons.shopping_cart_rounded),
                title: Text(context.translate('start_shopping')),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _ListAction.summary,
              child: ListTile(
                leading: const Icon(Icons.summarize_rounded),
                title: Text(context.translate('list_summary')),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _ListAction.activity,
              child: ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(context.translate('activity_log')),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _ListAction.quickAdd,
              child: ListTile(
                leading: const Icon(Icons.bolt_rounded),
                title: Text(context.translate('quick_add')),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _togglePurchased(String itemId, bool isPurchased) async {
    final itemsAsync = ref.read(
      shoppingItemsForHomeProvider(_itemsProviderParams),
    );
    final items = itemsAsync.value ?? [];
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;

    final repository = ref.read(
      shoppingItemRepositoryForHomeProvider(widget.homeId),
    );

    try {
      final useCase = MarkItemPurchasedUseCase(repository);
      await useCase(itemId: itemId, isPurchased: isPurchased);
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }

  Future<void> _handleQuantityTap(String itemId) async {
    final itemsAsync = ref.read(
      shoppingItemsForHomeProvider(_itemsProviderParams),
    );
    final items = itemsAsync.value ?? [];
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null || item.isPurchased) return;

    final repository = ref.read(
      shoppingItemRepositoryForHomeProvider(widget.homeId),
    );
    final unitsAsync = ref.read(unitsProvider(null));
    final units = unitsAsync.value ?? [];
    final unit = units.where((u) => u.id == item.unitId).firstOrNull;

    final result = await showDialog<double>(
      context: context,
      builder: (context) =>
          PartialPurchaseDialog(item: item, unitName: unit?.symbol),
    );

    if (result != null && result > 0 && mounted) {
      try {
        final useCase = UpdateItemPurchaseStateUseCase(repository);
        await useCase(itemId: item.id, purchasedQuantity: result);
        ref.invalidate(shoppingItemsForHomeProvider(_itemsProviderParams));
      } catch (e) {
        if (mounted) {
          SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        }
      }
    }
  }

  Future<void> _deleteItem(ShoppingItemModel item) async {
    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
      final useCase = DeleteItemUseCase(repository);

      final deletedItem = await useCase.callAndReturn(itemId: item.id);

      if (mounted && deletedItem != null) {
        final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
        if (hapticEnabled) {
          HapticFeedback.mediumImpact();
        }
        setState(() => _lastDeletedItem = deletedItem);

        SawaSnackBar.success(
          context,
          context.translate(
            'deleted_item_success',
            arguments: {'name': item.name},
          ),
          actionLabel: context.translate('undo'),
          onAction: () => _undoDelete(),
        );

        _undoTimer?.cancel();
        _undoTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _lastDeletedItem = null);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }

  Future<void> _undoDelete() async {
    if (_lastDeletedItem == null) return;

    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
      final useCase = DeleteItemUseCase(repository);
      await useCase.restoreItem(item: _lastDeletedItem!);

      _undoTimer?.cancel();
      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (hapticEnabled) {
        HapticFeedback.lightImpact();
      }
      if (mounted) {
        setState(() => _lastDeletedItem = null);
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }
}
