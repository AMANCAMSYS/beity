import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../providers/realtime_providers.dart';
import '../widgets/shopping_item_tile_widget.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/presence_indicator_widget.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/item_updated_toast.dart';
import '../../domain/usecases/mark_item_purchased_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../data/models/shopping_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../offline_queue/presentation/widgets/connectivity_listener.dart';
import '../../../offline_queue/presentation/widgets/sync_status_banner.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../offline_queue/domain/entities/sync_status.dart';
import '../../../../core/services/realtime_service.dart';

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState
    extends ConsumerState<ShoppingListDetailScreen> {
  // Undo delete state
  ShoppingItemModel? _lastDeletedItem;
  Timer? _undoTimer;

  // Search/filter state
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategoryId;

  // Category expansion state
  final Map<String?, bool> _expandedCategories = {};

  // Conflict highlight state
  final Map<String, DateTime> _highlightedItems = {};

  @override
  void initState() {
    super.initState();
    _joinPresence();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _searchController.dispose();
    _leavePresence();
    super.dispose();
  }

  void _joinPresence() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final service = ref.read(realtimeServiceProvider);
    final channelName = 'presence:list:${widget.listId}';
    service.watchPresence(
      channelName: channelName,
      userPayload: PresencePayload(
        userId: currentUser.id,
        displayName: currentUser.userMetadata?['full_name'] as String? ?? 'مستخدم',
        avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
      ),
    );
  }

  void _leavePresence() {
    final service = ref.read(realtimeServiceProvider);
    final channelName = 'presence:list:${widget.listId}';
    service.leavePresence(channelName: channelName);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(widget.listId));
    final connectionState = ref.watch(connectionStateProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    final list = listAsync.valueOrNull;
    final homeId = list?.homeId ?? '';
    final presenceAsync = ref.watch(presenceProvider(widget.listId));

    // Load units for display
    final unitsAsync = ref.watch(unitsProvider(null));
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.symbol.isNotEmpty ? '${unit.name} (${unit.symbol})' : unit.name;
      }
    });

    // Offline queue status
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final isOffline = connectivityStatus.valueOrNull?.isOffline ?? false;
    final pendingCount = homeId.isNotEmpty
        ? ref.watch(pendingCountProvider(homeId)).valueOrNull ?? 0
        : 0;
    final failedEntries = homeId.isNotEmpty
        ? ref
            .watch(offlineQueueRepositoryProvider)
            .getFailedEntries(homeId)
            .then((entries) => entries.length)
        : Future.value(0);

    return ConnectivityListener(
      homeId: homeId,
      child: Scaffold(
      appBar: AppBar(
        title: listAsync.when(
          data: (list) => Text(list?.name ?? 'قائمة التسوق'),
          loading: () => const Text('قائمة التسوق'),
          error: (_, __) => const Text('قائمة التسوق'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              final list = listAsync.valueOrNull;
              if (list != null) {
                context.push('/shopping-list/${widget.listId}/shopping-mode',
                    extra: {
                      'homeId': list.homeId,
                      'listName': list.name,
                    });
              }
            },
            tooltip: 'Start Shopping',
          ),
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            onPressed: () =>
                context.push('/shopping-list/${widget.listId}/summary'),
            tooltip: 'ملخص القائمة',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(
              '/shopping-list/${widget.listId}/activity',
              extra: {
                'homeId': list?.homeId ?? '',
                'listName': list?.name ?? 'القائمة',
              },
            ),
            tooltip: 'سجل النشاطات',
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline sync status banner
          FutureBuilder<int>(
            future: failedEntries,
            builder: (context, snapshot) {
              return SyncStatusBanner(
                pendingCount: pendingCount,
                failedCount: snapshot.data ?? 0,
                isOffline: isOffline,
                onRetryAll: () => _retryFailedEntries(homeId),
              );
            },
          ),
          // Connection status
          connectionState.when(
            data: (state) => ConnectionStatusWidget(connectionState: state),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Presence indicators
          presenceAsync.when(
            data: (presences) => PresenceIndicatorWidget(
              presences: presences,
              currentUserId: currentUser?.id ?? '',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Main content
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }

                var filtered = items;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((i) => i.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (_filterCategoryId != null) {
                  filtered = filtered
                      .where((i) => i.categoryId == _filterCategoryId)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return _buildNoResultsState(context);
                }

                final grouped = <String?, List<ShoppingItemModel>>{};
                for (final item in filtered) {
                  grouped
                      .putIfAbsent(item.categoryId, () => [])
                      .add(item);
                }
                for (final group in grouped.values) {
                  group.sort((a, b) {
                    if (a.isPurchased == b.isPurchased) return 0;
                    return a.isPurchased ? 1 : -1;
                  });
                }

                final categoriesAsync = ref.watch(categoriesProvider(homeId));

                final unpurchasedTotal = items
                    .where((i) => !i.isPurchased && i.price != null)
                    .fold<double>(0, (sum, i) => sum + i.price!);

                return Column(
                  children: [
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
                            fillColor: Theme.of(context).cardColor,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          autofocus: true,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    categoriesAsync.when(
                      data: (categories) => CategoryFilterWidget(
                        categories: categories,
                        selectedCategoryId: _filterCategoryId,
                        onCategorySelected: (id) {
                          setState(() => _filterCategoryId = id);
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          ...grouped.entries.map((entry) {
                            final categoryId = entry.key;
                            final groupItems = entry.value;
                            final isExpanded =
                                _expandedCategories[categoryId] ?? true;

                            return _buildCategoryGroup(
                              context,
                              categoryId: categoryId,
                              items: groupItems,
                              isExpanded: isExpanded,
                              homeId: homeId,
                              unitNames: unitNames,
                            );
                          }),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    if (unpurchasedTotal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المجموع المتوقع',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${unpurchasedTotal.toStringAsFixed(2)} ر.س',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('خطأ: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/shopping-list/${widget.listId}/add-item'),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
    ),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context, {
    required String? categoryId,
    required List<ShoppingItemModel> items,
    required bool isExpanded,
    required String homeId,
    required Map<String, String> unitNames,
  }) {
    final categoryName = _getCategoryName(categoryId, homeId);
    final unpurchasedCount = items.where((i) => !i.isPurchased).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[categoryId] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unpurchasedCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...items.map((item) {
            // Check if item has pending offline changes
            final queueEntries = ref.watch(queueEntriesProvider(homeId));
            final hasPending = queueEntries.when(
              data: (entries) => entries.any(
                (e) => e.entityId == item.id && e.isPending,
              ),
              loading: () => false,
              error: (_, __) => false,
            );

            return ShoppingItemTileWidget(
              item: item,
              unitName: item.unitId != null ? unitNames[item.unitId] : null,
              highlightUntil: _highlightedItems[item.id],
              showPendingIndicator: hasPending,
              onTogglePurchased: () =>
                  _togglePurchased(item.id, !item.isPurchased),
              onEdit: () => context.push(
                  '/shopping-list/${widget.listId}/edit-item/${item.id}'),
              onDelete: () => _deleteItem(item),
            );
          }),
      ],
    );
  }

  String _getCategoryName(String? categoryId, String homeId) {
    if (categoryId == null) return 'بدون تصنيف';

    final categoriesAsync = ref.read(categoriesProvider(homeId));
    return categoriesAsync.when(
      data: (categories) {
        final cat = categories.where((c) => c.id == categoryId).firstOrNull;
        return cat?.name ?? 'بدون تصنيف';
      },
      loading: () => 'بدون تصنيف',
      error: (_, __) => 'بدون تصنيف',
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'القائمة فارغة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة منتجات',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterCategoryId = null;
                _searchController.clear();
              });
            },
            child: const Text('مسح الفلاتر'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePurchased(String itemId, bool isPurchased) async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = MarkItemPurchasedUseCase(repository);
    await useCase(itemId: itemId, isPurchased: isPurchased);
  }

  Future<void> _deleteItem(ShoppingItemModel item) async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = DeleteItemUseCase(repository);

    final deletedItem = await useCase.callAndReturn(itemId: item.id);

    if (mounted && deletedItem != null) {
      setState(() => _lastDeletedItem = deletedItem);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف "${item.name}"'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () => _undoDelete(),
          ),
        ),
      );

      _undoTimer?.cancel();
      _undoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _lastDeletedItem = null);
        }
      });
    }
  }

  Future<void> _undoDelete() async {
    if (_lastDeletedItem == null) return;

    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = DeleteItemUseCase(repository);
    await useCase.restoreItem(item: _lastDeletedItem!);

    _undoTimer?.cancel();
    if (mounted) {
      setState(() => _lastDeletedItem = null);
    }
  }

  Future<void> _retryFailedEntries(String homeId) async {
    final repository = ref.read(offlineQueueRepositoryProvider);
    final failedEntries = await repository.getFailedEntries(homeId);

    for (final entry in failedEntries) {
      await repository.updateEntryStatus(
        entryId: entry.id!,
        status: SyncStatus.pending,
      );
    }

    // Refresh providers
    ref.invalidate(queueEntriesProvider(homeId));
    ref.invalidate(pendingCountProvider(homeId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري إعادة محاولة ${failedEntries.length} عنصر'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
