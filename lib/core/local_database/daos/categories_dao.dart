import 'package:drift/drift.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class CategoriesDao {
  CategoriesDao(this.db);

  final AppDatabase db;

  Future<List<CategoryModel>> getCategories({
    String? homeId,
    String? type,
  }) async {
    final query = db.select(db.localCategories)
      ..where(
        (tbl) =>
            tbl.deletedAt.isNull() &
            (type == null ? const Constant(true) : tbl.type.equals(type)) &
            (homeId == null || homeId.isEmpty
                ? tbl.isDefault.equals(true)
                : (tbl.isDefault.equals(true) | tbl.homeId.equals(homeId))),
      )
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder)]);
    final rows = await query.get();
    return rows.map((row) => row.toCategoryModel()).toList();
  }

  Stream<List<CategoryModel>> watchCategories({String? homeId, String? type}) {
    final query = db.select(db.localCategories)
      ..where(
        (tbl) =>
            tbl.deletedAt.isNull() &
            (type == null ? const Constant(true) : tbl.type.equals(type)) &
            (homeId == null || homeId.isEmpty
                ? tbl.isDefault.equals(true)
                : (tbl.isDefault.equals(true) | tbl.homeId.equals(homeId))),
      );
    return query.watch().map(
      (rows) => rows.map((row) => row.toCategoryModel()).toList(),
    );
  }

  Future<CategoryModel?> getCategoryById(String categoryId) async {
    final row = await (db.select(
      db.localCategories,
    )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();
    return row?.toCategoryModel();
  }

  Future<void> upsertCategories(List<CategoryModel> categories) async {
    if (categories.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localCategories,
        categories.map((category) => category.toLocalCompanion()).toList(),
      );
    });
  }

  Future<void> softDeleteCategory(String categoryId, DateTime deletedAt) {
    return (db.update(
      db.localCategories,
    )..where((tbl) => tbl.id.equals(categoryId))).write(
      LocalCategoriesCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }
}
