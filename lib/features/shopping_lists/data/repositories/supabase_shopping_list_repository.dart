import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../models/item_template_model.dart';
import '../../presentation/providers/shopping_items_provider.dart';
import 'shopping_list_repository.dart';

class SupabaseShoppingListRepository implements ShoppingListRepository {
  final SupabaseClient _client;

  Map<String, String>? _unitCache;
  DateTime? _unitCacheTime;

  SupabaseShoppingListRepository(this._client);

  // Shopping Lists

  @override
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
  }) async {
    var query = _client
        .from('shopping_lists')
        .select()
        .eq('home_id', homeId)
        .filter('deleted_at', 'is', null);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('updated_at', ascending: false);
    return (response as List)
        .map((json) => ShoppingListModel.fromJson(json))
        .toList();
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
    required String homeId,
    required String name,
    String? description,
    String? icon,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final response = await _client
        .from('shopping_lists')
        .insert({
          'home_id': homeId,
          'title': name,
          'type': 'grocery',
          'icon': icon ?? 'shopping_cart',
          'created_by': user.id,
        })
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
  Future<void> deleteShoppingList({
    required String listId,
  }) async {
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

  @override
  Stream<List<ShoppingListModel>> watchShoppingLists({
    required String homeId,
  }) {
    final controller = StreamController<List<ShoppingListModel>>();
    
    // Initial fetch
    _fetchShoppingLists(homeId).then((lists) {
      if (!controller.isClosed) {
        controller.add(lists);
      }
    }).catchError((e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    });
    
    // Set up realtime subscription
    try {
      final subscription = _client
          .from('shopping_lists')
          .stream(primaryKey: ['id'])
          .eq('home_id', homeId)
          .order('updated_at', ascending: false)
          .map((response) => response
              .map((json) => ShoppingListModel.fromJson(json))
              .where((list) => list.deletedAt == null)
              .toList())
          .listen(
            (lists) {
              if (!controller.isClosed) {
                controller.add(lists);
              }
            },
            onError: (error) {
              // On error, refetch manually
              _fetchShoppingLists(homeId).then((lists) {
                if (!controller.isClosed) {
                  controller.add(lists);
                }
              }).catchError((e) {
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
      _fetchShoppingLists(homeId).then((lists) {
        if (!controller.isClosed) {
          controller.add(lists);
        }
      });
    }
    
    return controller.stream;
  }
  
  Future<List<ShoppingListModel>> _fetchShoppingLists(String homeId) async {
    final response = await _client
        .from('shopping_lists')
        .select()
        .eq('home_id', homeId)
        .filter('deleted_at', 'is', null)
        .order('updated_at', ascending: false);
    
    return (response as List)
        .map((json) => ShoppingListModel.fromJson(json))
        .toList();
  }

  // Shopping Items

  @override
  Future<List<ShoppingItemModel>> getShoppingItems({
    required String listId,
  }) async {
    final response = await _client
        .from('shopping_items')
        .select()
        .eq('list_id', listId) // Database uses 'list_id'
        .filter('deleted_at', 'is', null)
        .order('status', ascending: true)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ShoppingItemModel.fromJson(json))
        .toList();
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
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final payload = <String, dynamic>{
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'estimated_price': price,
      'currency': currency ?? 'TRY',
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
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user?.id,
    };
    if (name != null) updates['name'] = name;
    if (quantity != null) updates['quantity'] = quantity;
    if (purchasedQuantity != null) updates['purchased_quantity'] = purchasedQuantity;
    if (unitId != null) updates['unit_id'] = unitId;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (price != null) updates['estimated_price'] = price;
    if (notes != null) updates['note'] = notes;

    final response = await _client
        .from('shopping_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();

    return ShoppingItemModel.fromJson(response);
  }

  @override
  Future<void> deleteShoppingItem({
    required String itemId,
  }) async {
    final user = _client.auth.currentUser;
    await _client
        .from('shopping_items')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user?.id,
        })
        .eq('id', itemId);
  }

  @override
  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
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

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItems({
    required String listId,
  }) {
    final controller = StreamController<List<ShoppingItemModel>>();
    
    // Initial fetch
    _fetchShoppingItems(listId).then((items) {
      if (!controller.isClosed) {
        controller.add(items);
      }
    }).catchError((e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    });
    
    // Set up realtime subscription
    try {
      final subscription = _client
          .from('shopping_items')
          .stream(primaryKey: ['id'])
          .eq('list_id', listId)
          .order('status', ascending: true)
          .order('name', ascending: true)
          .map((response) => response
              .map((json) => ShoppingItemModel.fromJson(json))
              .where((item) => item.deletedAt == null)
              .toList())
          .listen(
            (items) {
              if (!controller.isClosed) {
                controller.add(items);
              }
            },
            onError: (error) {
              // On error, refetch manually
              _fetchShoppingItems(listId).then((items) {
                if (!controller.isClosed) {
                  controller.add(items);
                }
              }).catchError((e) {
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
      _fetchShoppingItems(listId).then((items) {
        if (!controller.isClosed) {
          controller.add(items);
        }
      });
    }
    
    return controller.stream;
  }
  
  Future<List<ShoppingItemModel>> _fetchShoppingItems(String listId) async {
    final response = await _client
        .from('shopping_items')
        .select()
        .eq('list_id', listId)
        .filter('deleted_at', 'is', null)
        .order('status', ascending: true)
        .order('name', ascending: true);
    
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
      throw Exception('يجب تسجيل الدخول أولاً');
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
  Future<void> incrementTemplateUsage({
    required String templateId,
  }) async {
    await _client.rpc(
      'increment_template_usage',
      params: {'template_id': templateId},
    );
  }

  @override
  Stream<List<ItemTemplateModel>> watchItemTemplates({
    required String homeId,
  }) {
    final controller = StreamController<List<ItemTemplateModel>>();
    
    // Initial fetch
    _fetchItemTemplates(homeId).then((templates) {
      if (!controller.isClosed) {
        controller.add(templates);
      }
    }).catchError((e) {
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
          .map((response) =>
              response.map((json) => ItemTemplateModel.fromJson(json)).toList())
          .listen(
            (templates) {
              if (!controller.isClosed) {
                controller.add(templates);
              }
            },
            onError: (error) {
              // On error, refetch manually
              _fetchItemTemplates(homeId).then((templates) {
                if (!controller.isClosed) {
                  controller.add(templates);
                }
              }).catchError((e) {
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
    if (query.trim().isEmpty) return [];

    final suggestions = <AutocompleteSuggestion>[];
    final seenNames = <String>{};

    // Fetch all units for name resolution (cached for 5 minutes)
    Map<String, String> unitMap;
    final cacheNow = DateTime.now();
    if (_unitCache != null && _unitCacheTime != null && cacheNow.difference(_unitCacheTime!).inMinutes < 5) {
      unitMap = _unitCache!;
    } else {
      final unitsData = await _client.from('units').select('id, name, symbol');
      unitMap = <String, String>{};
      for (final u in unitsData as List<dynamic>) {
        final map = u as Map<String, dynamic>;
        final symbol = map['symbol'] as String? ?? '';
        unitMap[map['id'] as String] = symbol.isNotEmpty ? '${map['name']} ($symbol)' : map['name'] as String;
      }
      _unitCache = unitMap;
      _unitCacheTime = cacheNow;
    }

    // 1. Search item templates
    final templates = await _client
        .from('item_templates')
        .select('id, name, default_quantity, default_unit_id')
        .eq('home_id', homeId)
        .ilike('name', '%$query%')
        .order('usage_count', ascending: false)
        .limit(limit);

    for (final t in templates as List<dynamic>) {
      final map = t as Map<String, dynamic>;
      final name = map['name'] as String;
      if (seenNames.add(name.toLowerCase())) {
        final unitId = map['default_unit_id'] as String?;
        suggestions.add(AutocompleteSuggestion(
          name: name,
          quantity: (map['default_quantity'] as num?)?.toDouble() ?? 1,
          unitName: unitId != null ? unitMap[unitId] : null,
          sourceId: map['id'] as String,
          isTemplate: true,
        ));
      }
    }

    // 2. Search distinct item names from shopping items in the same home
    if (suggestions.length < limit) {
      final lists = await _client
          .from('shopping_lists')
          .select('id')
          .eq('home_id', homeId)
          .filter('deleted_at', 'is', null);

      final listIds =
          (lists as List<dynamic>).map((l) => (l as Map<String, dynamic>)['id'] as String).toList();

      if (listIds.isNotEmpty) {
        final items = await _client
            .from('shopping_items')
            .select('name, quantity, unit_id')
            .inFilter('list_id', listIds)
            .ilike('name', '%$query%')
            .limit(limit * 2);

        for (final item in items as List<dynamic>) {
          final map = item as Map<String, dynamic>;
          final name = map['name'] as String;
          if (seenNames.add(name.toLowerCase())) {
            final unitId = map['unit_id'] as String?;
            suggestions.add(AutocompleteSuggestion(
              name: name,
              quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
              unitName: unitId != null ? unitMap[unitId] : null,
              sourceId: null,
              isTemplate: false,
            ));
          }
          if (suggestions.length >= limit) break;
        }
      }
    }

    return suggestions.take(limit).toList();
  }

  @override
  Future<void> syncShoppingWithServer(String homeId) {
    throw UnimplementedError('syncShoppingWithServer is implemented in OfflineAwareShoppingRepository');
  }
}
