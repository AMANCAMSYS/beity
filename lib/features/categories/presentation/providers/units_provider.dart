import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/local_database/daos/units_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../data/models/unit_model.dart';
import '../../data/repositories/unit_repository.dart';
import '../../data/repositories/supabase_unit_repository.dart';

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return SupabaseUnitRepository(
    SupabaseService.client,
    UnitsDao(LocalDatabaseService.instance),
  );
});

final unitsProvider = FutureProvider.family<List<UnitModel>, String?>((
  ref,
  type,
) async {
  final repo = ref.read(unitRepositoryProvider);
  return repo.getUnits(type: type);
});

final unitsStreamProvider = StreamProvider.autoDispose
    .family<List<UnitModel>, String?>((ref, type) {
      final repo = ref.read(unitRepositoryProvider);
      return repo.watchUnits(type: type);
    });

class UnitNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<UnitModel> createUnit({
    required String name,
    required String symbol,
    required String type,
  }) async {
    state = const AsyncValue.loading();
    try {
      final unit = await ref
          .read(unitRepositoryProvider)
          .createUnit(name: name, symbol: symbol, type: type);
      state = const AsyncValue.data(null);
      return unit;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<UnitModel> updateUnit({
    required String unitId,
    String? name,
    String? symbol,
  }) async {
    state = const AsyncValue.loading();
    try {
      final unit = await ref
          .read(unitRepositoryProvider)
          .updateUnit(unitId: unitId, name: name, symbol: symbol);
      state = const AsyncValue.data(null);
      return unit;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteUnit({required String unitId}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(unitRepositoryProvider).deleteUnit(unitId: unitId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final unitNotifierProvider = AsyncNotifierProvider<UnitNotifier, void>(() {
  return UnitNotifier();
});
