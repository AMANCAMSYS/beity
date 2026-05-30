import 'dart:convert';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/unit_model.dart';
import 'unit_repository.dart';

class SupabaseUnitRepository implements UnitRepository {
  final SupabaseClient _client;

  SupabaseUnitRepository(this._client);

  @override
  Future<List<UnitModel>> getUnits({
    String? type,
  }) async {
    final cacheKey = 'cached_units_${type ?? 'none'}';
    try {
      var query = _client
          .from('units')
          .select()
          .eq('is_default', true);

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('name', ascending: true);
      final units = (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();

      // Cache units
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(units.map((u) => u.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      return units;
    } catch (e) {
      // Fallback to cache if offline
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list.map((json) => UnitModel.fromJson(json)).toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<UnitModel> createUnit({
    required String name,
    required String symbol,
    required String type,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check for duplicate name
    final existingName = await _client
        .from('units')
        .select('id')
        .eq('name', name)
        .maybeSingle();

    if (existingName != null) {
      throw Exception('اسم الوحدة موجود بالفعل');
    }

    // Check for duplicate symbol
    final existingSymbol = await _client
        .from('units')
        .select('id')
        .eq('symbol', symbol)
        .maybeSingle();

    if (existingSymbol != null) {
      throw Exception('رمز الوحدة موجود بالفعل');
    }

    final response = await _client
        .from('units')
        .insert({
          'name': name,
          'symbol': symbol,
          'type': type,
          'is_default': false,
        })
        .select()
        .single();

    return UnitModel.fromJson(response);
  }

  @override
  Future<UnitModel> updateUnit({
    required String unitId,
    String? name,
    String? symbol,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if unit is default
    final unit = await _client
        .from('units')
        .select('is_default')
        .eq('id', unitId)
        .single();

    if (unit['is_default'] == true) {
      throw Exception('لا يمكن تعديل الوحدات الافتراضية');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (symbol != null) updates['symbol'] = symbol;

    final response = await _client
        .from('units')
        .update(updates)
        .eq('id', unitId)
        .select()
        .single();

    return UnitModel.fromJson(response);
  }

  @override
  Future<void> deleteUnit({
    required String unitId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if unit is default
    final unit = await _client
        .from('units')
        .select('is_default')
        .eq('id', unitId)
        .single();

    if (unit['is_default'] == true) {
      throw Exception('لا يمكن حذف الوحدات الافتراضية');
    }

    await _client
        .from('units')
        .delete()
        .eq('id', unitId);
  }

  @override
  Future<UnitModel?> getUnitById({
    required String unitId,
  }) async {
    final response = await _client
        .from('units')
        .select()
        .eq('id', unitId)
        .maybeSingle();

    if (response == null) return null;
    return UnitModel.fromJson(response);
  }

  @override
  Stream<List<UnitModel>> watchUnits({
    String? type,
  }) async* {
    final cacheKey = 'cached_units_${type ?? 'none'}';

    // 1. Emit cached units immediately
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List<dynamic> list = jsonDecode(cached);
        yield list.map((json) => UnitModel.fromJson(json)).toList();
      }
    } catch (_) {}

    // 2. Subscribe to remote stream
    try {
      await for (final response in _client
          .from('units')
          .stream(primaryKey: ['id'])
          .order('name', ascending: true)) {
        final list = response
            .map((json) => UnitModel.fromJson(json))
            .where((unit) =>
                unit.isDefault &&
                (type == null || unit.type.name == type))
            .toList();

        try {
          final prefs = AppPreferences.instance;
          final rawJson = jsonEncode(list.map((u) => u.toJson()).toList());
          await prefs.setString(cacheKey, rawJson);
        } catch (_) {}

        yield list;
      }
    } catch (_) {
      // Absorb stream errors when offline
    }
  }
}
