import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../models/item_template_model.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import 'shopping_list_repository.dart';

class SupabaseShoppingListRepository implements ShoppingListRepository {
  static const int _pageSize = 500;

  final SupabaseClient _client;

  Map<String, String>? _unitCache;
  DateTime? _unitCacheTime;
  final Map<String, _AutocompleteCacheEntry> _autocompleteCache = {};

  SupabaseShoppingListRepository(this._client);

  // Shopping Lists

  @override
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
    bool includeDeleted = false,
  }) async {
    final result = <ShoppingListModel>[];

    for (var offset = 0; ; offset += _pageSize) {
      var query = _client.from('shopping_lists').select().eq('home_id', homeId);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (!includeDeleted) {
        query = query.filter('deleted_at', 'is', null);
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('updated_at', ascending: false)
          .range(offset, offset + _pageSize - 1);
      final page = (response as List)
          .map((json) => ShoppingListModel.fromJson(json))
          .toList();
      result.addAll(page);
      if (page.length < _pageSize) break;
    }

    return result;
  }

  @override
  Stream<List<ShoppingListModel>> watchShoppingLists({
    required String homeId,
    String? status,
  }) {
    return _client
        .from('shopping_lists')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .map((rows) {
          final lists = rows
              .map((json) => ShoppingListModel.fromJson(json))
              .where((list) => list.deletedAt == null)
              .where((list) => status == null || list.status.name == status)
              .toList();
          return lists;
        });
  }

  @override
  Future<ShoppingListModel?> getShoppingListById({
    required String listId,
  }) async {
    final response = await _client
        .from('shopping_lists')
        .select()
        .eq('id', listId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return ShoppingListModel.fromJson(response);
  }

  @override
  Future<ShoppingListModel> createShoppingList({
    String? id,
    required String homeId,
    required String name,
    String? description,
    String? icon,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final payload = <String, dynamic>{
      'home_id': homeId,
      'title': name,
      'type': description ?? 'grocery',
      'icon': icon ?? 'shopping_cart',
      'created_by': user.id,
    };
    if (id != null) {
      payload['id'] = id;
    }

    final response = await _client
        .from('shopping_lists')
        .insert(payload)
        .select()
        .single();

    return ShoppingListModel.fromJson(response);
  }

  @override
  Future<ShoppingListModel> updateShoppingList({
    required String listId,
    String? name,
    String? description,
    String? status,
  }) async {
    final user = _client.auth.currentUser;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user?.id,
    };
    if (name != null) updates['title'] = name;
    if (description != null) updates['type'] = description;
    if (status != null) updates['status'] = status;

    final response = await _client
        .from('shopping_lists')
        .update(updates)
        .eq('id', listId)
        .select()
        .single();

    return ShoppingListModel.fromJson(response);
  }

  @override
  Future<void> deleteShoppingList({required String listId}) async {
    final user = _client.auth.currentUser;
    await _client
        .from('shopping_lists')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user?.id,
        })
        .eq('id', listId);
  }

  // Shopping Items

  @override
  Future<List<ShoppingItemModel>> getShoppingItems({
    required String listId,
    bool includeDeleted = false,
  }) async {
    final result = <ShoppingItemModel>[];

    for (var offset = 0; ; offset += _pageSize) {
      var query = _client
          .from('shopping_items')
          .select()
          .eq('list_id', listId); // Database uses 'list_id'
      if (!includeDeleted) {
        query = query.filter('deleted_at', 'is', null);
      }

      final response = await query
          .order('status', ascending: true)
          .order('name', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final page = (response as List)
          .map((json) => ShoppingItemModel.fromJson(json))
          .toList();
      result.addAll(page);
      if (page.length < _pageSize) break;
    }

    return result;
  }

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItems({required String listId}) {
    return _client
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
        .order('status', ascending: true)
        .order('name', ascending: true)
        .map(
          (rows) => rows
              .map((json) => ShoppingItemModel.fromJson(json))
              .where((item) => item.deletedAt == null)
              .toList(),
        );
  }

  @override
  Future<Map<String, List<ShoppingItemModel>>> getShoppingItemsForLists({
    required List<String> listIds,
    bool includeDeleted = false,
  }) async {
    if (listIds.isEmpty) return {};

    final items = <ShoppingItemModel>[];
    for (var offset = 0; ; offset += _pageSize) {
      var query = _client
          .from('shopping_items')
          .select()
          .inFilter('list_id', listIds);
      if (!includeDeleted) {
        query = query.filter('deleted_at', 'is', null);
      }

      final response = await query
          .order('list_id', ascending: true)
          .order('status', ascending: true)
          .order('name', ascending: true)
          .range(offset, offset + _pageSize - 1);

      final page = (response as List)
          .map((json) => ShoppingItemModel.fromJson(json))
          .toList();
      items.addAll(page);
      if (page.length < _pageSize) break;
    }
    final grouped = <String, List<ShoppingItemModel>>{
      for (final listId in listIds) listId: <ShoppingItemModel>[],
    };
    for (final item in items) {
      grouped.putIfAbsent(item.shoppingListId, () => <ShoppingItemModel>[]);
      grouped[item.shoppingListId]!.add(item);
    }
    return grouped;
  }

  @override
  Future<ShoppingItemModel?> getShoppingItemById({
    required String itemId,
  }) async {
    final response = await _client
        .from('shopping_items')
        .select()
        .eq('id', itemId)
        .maybeSingle();

    if (response == null) return null;
    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<ShoppingItemModel> createShoppingItem({
    String? id,
    required String listId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? currency,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final payload = <String, dynamic>{
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'estimated_price': price,
      'currency': currency,
      'note': notes,
      'created_by': user.id,
    };
    if (id != null) {
      payload['id'] = id;
    }

    final response = await _client
        .from('shopping_items')
        .insert(payload)
        .select()
        .single();

    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<ShoppingItemModel> updateShoppingItem({
    required String itemId,
    String? name,
    double? quantity,
    double? purchasedQuantity,
    Object? unitId = shoppingFieldUnchanged,
    Object? categoryId = shoppingFieldUnchanged,
    Object? price = shoppingFieldUnchanged,
    Object? notes = shoppingFieldUnchanged,
  }) async {
    final user = _client.auth.currentUser;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user?.id,
    };
    if (name != null) updates['name'] = name;
    if (quantity != null) updates['quantity'] = quantity;
    if (purchasedQuantity != null) {
      updates['purchased_quantity'] = purchasedQuantity;
    }
    if (!identical(unitId, shoppingFieldUnchanged)) {
      updates['unit_id'] = unitId as String?;
    }
    if (!identical(categoryId, shoppingFieldUnchanged)) {
      updates['category_id'] = categoryId as String?;
    }
    if (!identical(price, shoppingFieldUnchanged)) {
      updates['estimated_price'] = price as double?;
    }
    if (!identical(notes, shoppingFieldUnchanged)) {
      updates['note'] = notes as String?;
    }

    final response = await _client
        .from('shopping_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();

    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<void> deleteShoppingItem({required String itemId}) async {
    final user = _client.auth.currentUser;
    final deletedAt = DateTime.now();
    await _client
        .from('shopping_items')
        .update({
          'deleted_at': deletedAt.toIso8601String(),
          'updated_at': deletedAt.toIso8601String(),
          'updated_by': user?.id,
        })
        .eq('id', itemId);
  }

  @override
  Future<ShoppingItemModel> restoreShoppingItem({
    required ShoppingItemModel item,
  }) async {
    final response = await _client.rpc(
      'restore_shopping_item',
      params: {'p_item_id': item.id},
    );

    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final updates = <String, dynamic>{
      'status': isPurchased ? 'completed' : 'pending',
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user.id,
    };

    if (isPurchased) {
      updates['completed_by'] = user.id;
      updates['completed_at'] = DateTime.now().toIso8601String();
    } else {
      updates['completed_by'] = null;
      updates['completed_at'] = null;
      updates['purchased_quantity'] = 0.0;
    }

    final response = await _client
        .from('shopping_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();

    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<ShoppingItemModel> updateItemPurchaseState({
    required String itemId,
    required double purchasedQuantity,
  }) async {
    final response = await _client.rpc<Map<String, dynamic>>(
      'set_shopping_item_purchase_state',
      params: {'p_item_id': itemId, 'p_purchased_quantity': purchasedQuantity},
    );

    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<List<ShoppingItemModel>> getPurchaseHistory({
    required String homeId,
    int limit = 50,
  }) async {
    final response = await _client
        .from('shopping_items')
        .select('*, shopping_lists!inner(home_id)')
        .eq('shopping_lists.home_id', homeId)
        .eq('status', 'completed') // Database uses 'status'
        .order('completed_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ShoppingItemModel.fromJson(json))
        .toList();
  }

  // Item Templates

  @override
  Future<List<ItemTemplateModel>> getItemTemplates({
    required String homeId,
  }) async {
    final response = await _client
        .from('item_templates')
        .select()
        .eq('home_id', homeId)
        .order('usage_count', ascending: false);

    return (response as List)
        .map((json) => ItemTemplateModel.fromJson(json))
        .toList();
  }

  @override
  Future<ItemTemplateModel> createItemTemplate({
    required String homeId,
    required String name,
    double defaultQuantity = 1,
    String? defaultUnitId,
    String? defaultCategoryId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('item_templates')
        .insert({
          'home_id': homeId,
          'name': name,
          'default_quantity': defaultQuantity,
          'default_unit_id': defaultUnitId,
          'default_category_id': defaultCategoryId,
          'created_by': user.id,
        })
        .select()
        .single();

    return ItemTemplateModel.fromJson(response);
  }

  @override
  Future<void> incrementTemplateUsage({required String templateId}) async {
    await _client.rpc(
      'increment_template_usage',
      params: {'template_id': templateId},
    );
  }

  @override
  Stream<List<ItemTemplateModel>> watchItemTemplates({required String homeId}) {
    final controller = StreamController<List<ItemTemplateModel>>();

    // Initial fetch
    _fetchItemTemplates(homeId)
        .then((templates) {
          if (!controller.isClosed) {
            controller.add(templates);
          }
        })
        .catchError((e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        });

    // Set up realtime subscription
    try {
      final subscription = _client
          .from('item_templates')
          .stream(primaryKey: ['id'])
          .eq('home_id', homeId)
          .order('usage_count', ascending: false)
          .map(
            (response) => response
                .map((json) => ItemTemplateModel.fromJson(json))
                .toList(),
          )
          .listen(
            (templates) {
              if (!controller.isClosed) {
                controller.add(templates);
              }
            },
            onError: (error) {
              // On error, refetch manually
              _fetchItemTemplates(homeId)
                  .then((templates) {
                    if (!controller.isClosed) {
                      controller.add(templates);
                    }
                  })
                  .catchError((e) {
                    if (!controller.isClosed) {
                      controller.addError(e);
                    }
                  });
            },
          );

      controller.onCancel = () {
        subscription.cancel();
      };
    } catch (e) {
      // If realtime fails, still provide data via polling
      _fetchItemTemplates(homeId).then((templates) {
        if (!controller.isClosed) {
          controller.add(templates);
        }
      });
    }

    return controller.stream;
  }

  Future<List<ItemTemplateModel>> _fetchItemTemplates(String homeId) async {
    final response = await _client
        .from('item_templates')
        .select()
        .eq('home_id', homeId)
        .order('usage_count', ascending: false);

    return (response as List)
        .map((json) => ItemTemplateModel.fromJson(json))
        .toList();
  }

  // Autocomplete suggestions

  Future<Map<String, String>> _getUnitMap() async {
    final cacheNow = DateTime.now();
    if (_unitCache != null &&
        _unitCacheTime != null &&
        cacheNow.difference(_unitCacheTime!).inMinutes < 5) {
      return _unitCache!;
    }

    final unitsData = await _client.from('units').select('id, name, symbol');
    final unitMap = <String, String>{};
    for (final u in unitsData as List<dynamic>) {
      final map = u as Map<String, dynamic>;
      final symbol = map['symbol'] as String? ?? '';
      unitMap[map['id'] as String] = symbol.isNotEmpty
          ? '${map['name']} ($symbol)'
          : map['name'] as String;
    }
    _unitCache = unitMap;
    _unitCacheTime = cacheNow;
    return unitMap;
  }

  Future<List<Map<String, dynamic>>> _searchAutocompleteTemplates({
    required String homeId,
    required String query,
    required int limit,
  }) async {
    final templates = await _client
        .from('item_templates')
        .select('id, name, default_quantity, default_unit_id')
        .eq('home_id', homeId)
        .ilike('name', '%$query%')
        .order('usage_count', ascending: false)
        .limit(limit);

    return (templates as List<dynamic>).cast<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> _searchAutocompleteItems({
    required String homeId,
    required String query,
    required int limit,
  }) async {
    try {
      final items = await _client
          .from('shopping_items')
          .select('name, quantity, unit_id')
          .eq('home_id', homeId)
          .filter('deleted_at', 'is', null)
          .ilike('name', '%$query%')
          .limit(limit * 2);

      return (items as List<dynamic>).cast<Map<String, dynamic>>().toList();
    } catch (_) {
      return _searchAutocompleteItemsViaLists(
        homeId: homeId,
        query: query,
        limit: limit,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _searchAutocompleteItemsViaLists({
    required String homeId,
    required String query,
    required int limit,
  }) async {
    final lists = await _client
        .from('shopping_lists')
        .select('id')
        .eq('home_id', homeId)
        .filter('deleted_at', 'is', null);

    final listIds = (lists as List<dynamic>)
        .map((l) => (l as Map<String, dynamic>)['id'] as String)
        .toList();

    if (listIds.isEmpty) return [];

    final items = await _client
        .from('shopping_items')
        .select('name, quantity, unit_id')
        .inFilter('list_id', listIds)
        .ilike('name', '%$query%')
        .limit(limit * 2);

    return (items as List<dynamic>).cast<Map<String, dynamic>>().toList();
  }

  @override
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.rpc(
      'sync_template_on_add',
      params: {
        'p_home_id': homeId,
        'p_name': name,
        'p_quantity': quantity,
        'p_unit_id': unitId,
        'p_category_id': categoryId,
        'p_user_id': user.id,
      },
    );
  }

  @override
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions({
    required String homeId,
    required String query,
    int limit = 10,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return [];

    final cacheKey = '$homeId|${normalizedQuery.toLowerCase()}|$limit';
    final cached = _autocompleteCache[cacheKey];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.createdAt).inSeconds < 20) {
      return cached.suggestions;
    }

    final suggestions = <AutocompleteSuggestion>[];
    final seenNames = <String>{};

    final results = await Future.wait<dynamic>([
      _getUnitMap(),
      _searchAutocompleteTemplates(
        homeId: homeId,
        query: normalizedQuery,
        limit: limit,
      ),
      _searchAutocompleteItems(
        homeId: homeId,
        query: normalizedQuery,
        limit: limit,
      ),
    ]);

    final unitMap = results[0] as Map<String, String>;
    final templates = results[1] as List<Map<String, dynamic>>;
    final items = results[2] as List<Map<String, dynamic>>;

    // 1. Search item templates
    for (final map in templates) {
      final name = map['name'] as String;
      if (seenNames.add(name.toLowerCase())) {
        final unitId = map['default_unit_id'] as String?;
        suggestions.add(
          AutocompleteSuggestion(
            name: name,
            quantity: (map['default_quantity'] as num?)?.toDouble() ?? 1,
            unitName: unitId != null ? unitMap[unitId] : null,
            sourceId: map['id'] as String,
            isTemplate: true,
          ),
        );
      }
    }

    // 2. Search distinct item names from shopping items in the same home
    if (suggestions.length < limit) {
      for (final map in items) {
        final name = map['name'] as String;
        if (seenNames.add(name.toLowerCase())) {
          final unitId = map['unit_id'] as String?;
          suggestions.add(
            AutocompleteSuggestion(
              name: name,
              quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
              unitName: unitId != null ? unitMap[unitId] : null,
              sourceId: null,
              isTemplate: false,
            ),
          );
        }
        if (suggestions.length >= limit) break;
      }
    }

    final limitedSuggestions = suggestions.take(limit).toList();
    _autocompleteCache[cacheKey] = _AutocompleteCacheEntry(
      suggestions: limitedSuggestions,
      createdAt: now,
    );
    return limitedSuggestions;
  }

  @override
  Future<void> syncShoppingWithServer(String homeId) async {
    // The real implementation is in OfflineAwareShoppingRepository.
    // This base implementation is a no-op fallback.
  }
}

class _AutocompleteCacheEntry {
  final List<AutocompleteSuggestion> suggestions;
  final DateTime createdAt;

  const _AutocompleteCacheEntry({
    required this.suggestions,
    required this.createdAt,
  });
}
