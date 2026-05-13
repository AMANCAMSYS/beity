import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_transaction_model.dart';
import 'inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  final SupabaseClient _client;

  SupabaseInventoryRepository(this._client);

  // Inventory Items

  @override
  Future<List<InventoryItemModel>> getInventoryItems({
    required String homeId,
  }) async {
    final response = await _client
        .from('inventory_items')
        .select()
        .eq('home_id', homeId)
        .filter('deleted_at', 'is', null)
        .order('category_id', ascending: true)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => InventoryItemModel.fromJson(json))
        .toList();
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
      throw Exception('يجب تسجيل الدخول أولاً');
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

    return InventoryItemModel.fromJson(response);
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
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final updates = <String, dynamic>{
      'updated_by': user.id,
    };
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

    return InventoryItemModel.fromJson(response);
  }

  @override
  Future<void> deleteInventoryItem({
    required String itemId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    await _client
        .from('inventory_items')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('id', itemId);
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
  }) {
    return _client
        .from('inventory_items')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('category_id', ascending: true)
        .order('name', ascending: true)
        .map((response) => response
            .map((json) => InventoryItemModel.fromJson(json))
            .where((item) => item.deletedAt == null)
            .toList());
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
      throw Exception('يجب تسجيل الدخول أولاً');
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
    return _client
        .from('inventory_transactions')
        .stream(primaryKey: ['id'])
        .eq('inventory_item_id', inventoryItemId)
        .order('created_at', ascending: false)
        .map((response) => response
            .map((json) => InventoryTransactionModel.fromJson(json))
            .toList());
  }
}
