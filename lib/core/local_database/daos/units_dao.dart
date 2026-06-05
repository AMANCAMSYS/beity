import 'package:drift/drift.dart';
import 'package:sawa/features/categories/data/models/unit_model.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class UnitsDao {
  UnitsDao(this.db);

  final AppDatabase db;

  Future<List<UnitModel>> getUnits({String? type}) async {
    final query = db.select(db.localUnits)
      ..where(
        (tbl) =>
            tbl.isDefault.equals(true) &
            (type == null ? const Constant(true) : tbl.type.equals(type)),
      )
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    final rows = await query.get();
    return rows.map((row) => row.toUnitModel()).toList();
  }

  Stream<List<UnitModel>> watchUnits({String? type}) {
    final query = db.select(db.localUnits)
      ..where(
        (tbl) =>
            tbl.isDefault.equals(true) &
            (type == null ? const Constant(true) : tbl.type.equals(type)),
      );
    return query.watch().map(
      (rows) => rows.map((row) => row.toUnitModel()).toList(),
    );
  }

  Future<UnitModel?> getUnitById(String unitId) async {
    final row = await (db.select(
      db.localUnits,
    )..where((tbl) => tbl.id.equals(unitId))).getSingleOrNull();
    return row?.toUnitModel();
  }

  Future<void> upsertUnits(List<UnitModel> units) async {
    if (units.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localUnits,
        units.map((unit) => unit.toLocalCompanion()).toList(),
      );
    });
  }

  Future<void> deleteUnit(String unitId) {
    return (db.delete(
      db.localUnits,
    )..where((tbl) => tbl.id.equals(unitId))).go();
  }
}
