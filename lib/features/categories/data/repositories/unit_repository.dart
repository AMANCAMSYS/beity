import '../models/unit_model.dart';

abstract class UnitRepository {
  Future<List<UnitModel>> getUnits({
    String? type,
  });

  Future<UnitModel> createUnit({
    required String name,
    required String symbol,
    required String type,
  });

  Future<UnitModel> updateUnit({
    required String unitId,
    String? name,
    String? symbol,
  });

  Future<void> deleteUnit({
    required String unitId,
  });

  Future<UnitModel?> getUnitById({
    required String unitId,
  });

  Stream<List<UnitModel>> watchUnits({
    String? type,
  });
}
