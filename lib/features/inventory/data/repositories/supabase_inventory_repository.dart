import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_transaction_model.dart';
import '../datasources/inventory_local_datasource.dart';
import 'inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  final SupabaseClient _client;
  final InventoryLocalDataSource _localDataSource;
  final SyncService _syncService;

  SupabaseInventoryRepository(
    this._client,
    this._localDataSource,
    this._syncService,
  );

  // Inventory Items

  @override
  Future<List<InventoryItemModel>> getInventoryItems({
    required String homeId,
  }) async {
    // 1. Try loading cached inventory first (Instant perceived loading)
    final cached = await _localDataSource.getInventoryItems(homeId: homeId);
    if (cached.isNotEmpty) {
      return cached;
    }

    // 2. Fetch from remote only if cache is empty
    try {
      final response = await _client
          .from('inventory_items')
          .select()
          .eq('home_id', homeId)
          .filter('deleted_at', 'is', null)
          .order('category_id', ascending: true)
          .order('name', ascending: true);

      final items = (response as List)
          .map((json) => InventoryItemModel.fromJson(json))
          .toList();

      // Save to local cache
      await _localDataSource.saveInventoryItems(homeId: homeId, items: items);
      await _localDataSource.saveInventoryItemsStreamCache(
        homeId: homeId,
        items: items,
      );

      return items;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<InventoryItemModel?> getInventoryItemById({
    required String itemId,
  }) async {
    final response = await _client
        .from('inventory_items')
        .select()
        .eq('id', itemId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return InventoryItemModel.fromJson(response);
  }

  @override
  Future<InventoryItemModel> createInventoryItem({
    required String homeId,
    required String name,
    double quantity = 0,
    String? unitId,
    String? categoryId,
    double? minQuantity,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('inventory_items')
        .insert({
          'home_id': homeId,
          'name': name,
          'quantity': quantity,
          'unit_id': unitId,
          'category_id': categoryId,
          'min_quantity': minQuantity,
          'notes': notes,
          'created_by': user.id,
          'updated_by': user.id,
        })
        .select()
        .single();

    final item = InventoryItemModel.fromJson(response);

    // Update local cache and notify UI
    await _refreshLocalCache(homeId);
    unawaited(_sendStockThresholdNotification(previous: null, current: item));

    return item;
  }

  @override
  Future<InventoryItemModel> updateInventoryItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? minQuantity,
    String? notes,
    List<String> fieldsToNull = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    InventoryItemModel? previous;
    try {
      previous = await getInventoryItemById(itemId: itemId);
    } catch (_) {}

    final updates = <String, dynamic>{'updated_by': user.id};
    if (name != null) updates['name'] = name;
    if (quantity != null) updates['quantity'] = quantity;
    if (unitId != null) updates['unit_id'] = unitId;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (minQuantity != null) updates['min_quantity'] = minQuantity;
    if (notes != null) updates['notes'] = notes;

    // Explicitly set fields to null
    for (final field in fieldsToNull) {
      updates[field] = null;
    }

    final response = await _client
        .from('inventory_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();

    final item = InventoryItemModel.fromJson(response);

    // Update local cache and notify UI
    await _refreshLocalCache(item.homeId);
    unawaited(
      _sendStockThresholdNotification(previous: previous, current: item),
    );

    return item;
  }

  @override
  Future<void> deleteInventoryItem({required String itemId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final item = await getInventoryItemById(itemId: itemId);
    if (item == null) return;

    await _client
        .from('inventory_items')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('id', itemId);

    await _refreshLocalCache(item.homeId);
  }

  @override
  Future<InventoryItemModel?> findDuplicateItem({
    required String homeId,
    required String name,
    String? unitId,
  }) async {
    var query = _client
        .from('inventory_items')
        .select()
        .eq('home_id', homeId)
        .ilike('name', name)
        .filter('deleted_at', 'is', null);

    if (unitId != null) {
      query = query.eq('unit_id', unitId);
    } else {
      query = query.filter('unit_id', 'is', null);
    }

    final response = await query.maybeSingle();
    if (response == null) return null;
    return InventoryItemModel.fromJson(response);
  }

  @override
  Future<void> transferItemsBatch({
    required String listId,
    required String homeId,
    required List<Map<String, dynamic>> items,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    if (items.isEmpty) return;

    await _client.rpc(
      'transfer_items_to_inventory',
      params: {'p_list_id': listId, 'p_home_id': homeId, 'p_items': items},
    );

    await _refreshLocalCache(homeId);
  }

  @override
  Future<List<InventoryItemModel>> searchInventoryItems({
    required String homeId,
    required String query,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    final response = await _client
        .from('inventory_items')
        .select()
        .eq('home_id', homeId)
        .ilike('name', '%$query%')
        .filter('deleted_at', 'is', null)
        .order('name', ascending: true)
        .limit(limit);

    return (response as List)
        .map((json) => InventoryItemModel.fromJson(json))
        .toList();
  }

  @override
  Stream<List<InventoryItemModel>> watchInventoryItems({
    required String homeId,
  }) async* {
    // 1. Emit cached inventory items instantly (0 network requests, instant perceived loading)
    final cached = await _localDataSource.getInventoryItemsStreamCache(
      homeId: homeId,
    );
    yield cached;

    // 2. If cache is empty, fetch from server and populate cache
    if (cached.isEmpty) {
      try {
        final response = await _client
            .from('inventory_items')
            .select()
            .eq('home_id', homeId)
            .filter('deleted_at', 'is', null)
            .order('category_id', ascending: true)
            .order('name', ascending: true);

        final items = (response as List)
            .map((json) => InventoryItemModel.fromJson(json))
            .toList();

        await _localDataSource.saveInventoryItems(homeId: homeId, items: items);
        await _localDataSource.saveInventoryItemsStreamCache(
          homeId: homeId,
          items: items,
        );
        yield items;
      } catch (_) {
        // Server fetch failed — stream will still update via LocalCacheNotifier
      }
    }

    // 3. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'inventory_items') {
        yield await _localDataSource.getInventoryItemsStreamCache(
          homeId: homeId,
        );
      }
    }
  }

  // Inventory Transactions

  @override
  Future<InventoryTransactionModel> createTransaction({
    required String inventoryItemId,
    required String homeId,
    required double previousQuantity,
    required double newQuantity,
    required String changeReason,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('inventory_transactions')
        .insert({
          'inventory_item_id': inventoryItemId,
          'home_id': homeId,
          'previous_quantity': previousQuantity,
          'new_quantity': newQuantity,
          'change_reason': changeReason,
          'changed_by': user.id,
        })
        .select()
        .single();

    return InventoryTransactionModel.fromJson(response);
  }

  @override
  Future<List<InventoryTransactionModel>> getTransactions({
    required String inventoryItemId,
    int limit = 50,
  }) async {
    final response = await _client
        .from('inventory_transactions')
        .select()
        .eq('inventory_item_id', inventoryItemId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => InventoryTransactionModel.fromJson(json))
        .toList();
  }

  @override
  Stream<List<InventoryTransactionModel>> watchTransactions({
    required String inventoryItemId,
  }) {
    // Keep transactions simple (online stream or fallback)
    return _client
        .from('inventory_transactions')
        .stream(primaryKey: ['id'])
        .eq('inventory_item_id', inventoryItemId)
        .order('created_at', ascending: false)
        .map(
          (response) => response
              .map((json) => InventoryTransactionModel.fromJson(json))
              .toList(),
        );
  }

  @override
  Future<void> syncInventoryWithServer(String homeId) async {
    try {
      final serverUpdates = await _syncService.getServerLastUpdates(homeId);
      final serverInventoryMaxUpdate = serverUpdates['inventory_items'];

      if (serverInventoryMaxUpdate != null) {
        final localSyncTime = _syncService.getLocalSyncTime(
          homeId,
          'inventory_items',
        );
        final cachedItems = await _localDataSource.getInventoryItemsStreamCache(
          homeId: homeId,
        );
        final isCacheEmpty = cachedItems.isEmpty;

        // Delta Sync check: Only pull if the server has newer updates OR local cache is empty!
        if (isCacheEmpty || serverInventoryMaxUpdate.isAfter(localSyncTime)) {
          final response = await _client
              .from('inventory_items')
              .select()
              .eq('home_id', homeId)
              .filter('deleted_at', 'is', null)
              .order('category_id', ascending: true)
              .order('name', ascending: true);

          final items = (response as List)
              .map((json) => InventoryItemModel.fromJson(json))
              .toList();

          // 1. Save pulled items into local stream cache
          await _localDataSource.saveInventoryItemsStreamCache(
            homeId: homeId,
            items: items,
          );

          // 2. Save pulled items into local cache
          await _localDataSource.saveInventoryItems(
            homeId: homeId,
            items: items,
          );

          // 3. Update the local sync time
          DateTime maxTs = DateTime.fromMillisecondsSinceEpoch(0);
          for (final i in items) {
            if (i.updatedAt != null && i.updatedAt!.isAfter(maxTs)) {
              maxTs = i.updatedAt!;
            }
            if (i.createdAt != null && i.createdAt!.isAfter(maxTs)) {
              maxTs = i.createdAt!;
            }
          }
          if (maxTs.year > 1970) {
            await _syncService.updateLocalSyncTime(
              homeId,
              'inventory_items',
              maxTs,
            );
          } else {
            await _syncService.updateLocalSyncTime(
              homeId,
              'inventory_items',
              DateTime.now(),
            );
          }

          // 4. Notify reactive UI stream that cache updated
          LocalCacheNotifier.notify(homeId, 'inventory_items');
        }
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _refreshLocalCache(String homeId) async {
    if (homeId.isEmpty) return;
    try {
      final response = await _client
          .from('inventory_items')
          .select()
          .eq('home_id', homeId)
          .filter('deleted_at', 'is', null)
          .order('category_id', ascending: true)
          .order('name', ascending: true);

      final items = (response as List)
          .map((json) => InventoryItemModel.fromJson(json))
          .toList();

      await _localDataSource.saveInventoryItemsStreamCache(
        homeId: homeId,
        items: items,
      );
      await _localDataSource.saveInventoryItems(homeId: homeId, items: items);
      LocalCacheNotifier.notify(homeId, 'inventory_items');
    } catch (_) {
      // Silent fail - cache refresh is best-effort
    }
  }

  Future<void> _sendStockThresholdNotification({
    required InventoryItemModel? previous,
    required InventoryItemModel current,
  }) async {
    final eventType = _stockThresholdEventType(
      previous: previous,
      current: current,
    );
    if (eventType == null) return;

    final user = _client.auth.currentUser;
    if (user == null || current.homeId.isEmpty) return;

    await NotificationService.sendInventoryNotification(
      homeId: current.homeId,
      actorId: user.id,
      inventoryItemId: current.id,
      eventType: eventType,
      context: {
        'item_name': current.name,
        'quantity': current.quantity.toStringAsFixed(
          current.quantity.truncateToDouble() == current.quantity ? 0 : 1,
        ),
      },
    );
  }

  String? _stockThresholdEventType({
    required InventoryItemModel? previous,
    required InventoryItemModel current,
  }) {
    final previousState = _stockState(previous);
    final currentState = _stockState(current);
    if (previousState == currentState) return null;

    return switch (currentState) {
      _StockState.out => 'inventory_out_of_stock',
      _StockState.low => 'inventory_low_stock',
      _StockState.normal => null,
    };
  }

  _StockState _stockState(InventoryItemModel? item) {
    if (item == null) return _StockState.normal;
    if (item.quantity <= 0) return _StockState.out;

    final minQuantity = item.minQuantity;
    if (minQuantity != null &&
        minQuantity > 0 &&
        item.quantity <= minQuantity) {
      return _StockState.low;
    }

    return _StockState.normal;
  }
}

enum _StockState { normal, low, out }
