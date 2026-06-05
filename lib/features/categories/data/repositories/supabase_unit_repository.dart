import 'dart:async';
import 'package:sawa/core/local_database/daos/units_dao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/unit_model.dart';
import 'unit_repository.dart';

class SupabaseUnitRepository implements UnitRepository {
  final SupabaseClient _client;
  final UnitsDao? _localDao;

  SupabaseUnitRepository(this._client, [this._localDao]);

  @override
  Future<List<UnitModel>> getUnits({String? type}) async {
    final cachedUnits = await _localDao?.getUnits(type: type);
    if (cachedUnits != null && cachedUnits.isNotEmpty) {
      return cachedUnits;
    }

    try {
      var query = _client.from('units').select().eq('is_default', true);

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('name', ascending: true);
      final units = (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();

      await _localDao?.upsertUnits(units);

      return units;
    } catch (_) {
      return cachedUnits ?? const [];
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
      throw Exception('must_login_first');
    }

    // Check for duplicate name
    final existingName = await _client
        .from('units')
        .select('id')
        .eq('name', name)
        .maybeSingle();

    if (existingName != null) {
      throw Exception('unit_name_exists');
    }

    // Check for duplicate symbol
    final existingSymbol = await _client
        .from('units')
        .select('id')
        .eq('symbol', symbol)
        .maybeSingle();

    if (existingSymbol != null) {
      throw Exception('unit_symbol_exists');
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

    final unit = UnitModel.fromJson(response);
    await _localDao?.upsertUnits([unit]);
    return unit;
  }

  @override
  Future<UnitModel> updateUnit({
    required String unitId,
    String? name,
    String? symbol,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    // Check if unit is default
    final existingUnit = await _client
        .from('units')
        .select('is_default')
        .eq('id', unitId)
        .single();

    if (existingUnit['is_default'] == true) {
      throw Exception('cannot_edit_default_units');
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

    final updatedUnit = UnitModel.fromJson(response);
    await _localDao?.upsertUnits([updatedUnit]);
    return updatedUnit;
  }

  @override
  Future<void> deleteUnit({required String unitId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    // Check if unit is default
    final unit = await _client
        .from('units')
        .select('is_default')
        .eq('id', unitId)
        .single();

    if (unit['is_default'] == true) {
      throw Exception('cannot_delete_default_units');
    }

    await _client.from('units').delete().eq('id', unitId);
    await _localDao?.deleteUnit(unitId);
  }

  @override
  Future<UnitModel?> getUnitById({required String unitId}) async {
    final cached = await _localDao?.getUnitById(unitId);
    if (cached != null) return cached;

    try {
      final response = await _client
          .from('units')
          .select()
          .eq('id', unitId)
          .maybeSingle();

      if (response == null) return null;
      final unit = UnitModel.fromJson(response);
      await _localDao?.upsertUnits([unit]);
      return unit;
    } catch (_) {
      return cached;
    }
  }

  @override
  Stream<List<UnitModel>> watchUnits({String? type}) async* {
    final localDao = _localDao;
    if (localDao != null) {
      final cached = await localDao.getUnits(type: type);
      if (cached.isEmpty) {
        unawaited(getUnits(type: type));
      }
      yield* localDao.watchUnits(type: type);
      return;
    }

    yield await getUnits(type: type);
  }
}
