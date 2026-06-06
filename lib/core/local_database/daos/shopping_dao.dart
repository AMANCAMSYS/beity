import 'package:drift/drift.dart';
import 'package:sawa/features/shopping_lists/data/models/item_template_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class ShoppingDao {
  ShoppingDao(this.db);

  final AppDatabase db;

  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
  }) async {
    final query = db.select(db.localShoppingLists)
      ..where(
        (tbl) =>
            tbl.homeId.equals(homeId) &
            tbl.deletedAt.isNull() &
            (status == null ? const Constant(true) : tbl.status.equals(status)),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
        (tbl) =>
            OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map((row) => row.toShoppingListModel()).toList();
  }

  Stream<List<ShoppingListModel>> watchShoppingLists({
    required String homeId,
    String? status,
  }) {
    final query = db.select(db.localShoppingLists)
      ..where(
        (tbl) =>
            tbl.homeId.equals(homeId) &
            tbl.deletedAt.isNull() &
            (status == null ? const Constant(true) : tbl.status.equals(status)),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
        (tbl) =>
            OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.toShoppingListModel()).toList(),
    );
  }

  Future<void> upsertShoppingLists(List<ShoppingListModel> lists) async {
    if (lists.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localShoppingLists,
        lists.map((list) => list.toLocalCompanion()).toList(),
      );
    });
  }

  Future<void> upsertShoppingListsWithLocalState({
    required List<ShoppingListModel> lists,
    required String localState,
    String? syncError,
  }) async {
    if (lists.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localShoppingLists,
        lists
            .map(
              (list) => list.toLocalCompanion(
                localState: localState,
                syncError: syncError,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> softDeleteShoppingList(
    String listId,
    DateTime deletedAt, {
    String localState = localStateSynced,
  }) {
    return (db.update(
      db.localShoppingLists,
    )..where((tbl) => tbl.id.equals(listId))).write(
      LocalShoppingListsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        localState: Value(localState),
        syncError: const Value(null),
      ),
    );
  }

  Future<List<ShoppingItemModel>> getShoppingItems(String listId) async {
    final rows =
        await (db.select(db.localShoppingItems)
              ..where(
                (tbl) => tbl.listId.equals(listId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([
                (tbl) => OrderingTerm(expression: tbl.status),
                (tbl) => OrderingTerm(expression: tbl.name),
              ]))
            .get();
    return rows.map((row) => row.toShoppingItemModel()).toList();
  }

  Stream<ShoppingListModel?> watchShoppingListById(String listId) {
    final query = db.select(db.localShoppingLists)
      ..where((tbl) => tbl.id.equals(listId) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull().map((row) => row?.toShoppingListModel());
  }

  Stream<List<ShoppingItemModel>> watchShoppingItems(String listId) {
    final query = db.select(db.localShoppingItems)
      ..where((tbl) => tbl.listId.equals(listId) & tbl.deletedAt.isNull());
    return query.watch().map(
      (rows) => rows.map((row) => row.toShoppingItemModel()).toList(),
    );
  }

  Future<void> upsertShoppingItems({
    required String listId,
    required List<ShoppingItemModel> items,
  }) async {
    if (items.isEmpty) return;
    final homeId = await _homeIdForList(listId);
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localShoppingItems,
        items
            .map((item) => item.toLocalCompanion(homeId: homeId ?? ''))
            .toList(),
      );
    });
  }

  Future<void> upsertShoppingItemsWithLocalState({
    required String listId,
    required List<ShoppingItemModel> items,
    required String localState,
    String? syncError,
    String? homeId,
  }) async {
    if (items.isEmpty) return;
    final resolvedHomeId = homeId ?? await _homeIdForList(listId);
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localShoppingItems,
        items
            .map(
              (item) => item.toLocalCompanion(
                homeId: resolvedHomeId ?? '',
                localState: localState,
                syncError: syncError,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> softDeleteShoppingItem(
    String itemId,
    DateTime deletedAt, {
    String localState = localStateSynced,
  }) {
    return (db.update(
      db.localShoppingItems,
    )..where((tbl) => tbl.id.equals(itemId))).write(
      LocalShoppingItemsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        localState: Value(localState),
        syncError: const Value(null),
      ),
    );
  }

  Future<Map<String, List<ShoppingItemModel>>> getShoppingItemsForLists(
    List<String> listIds,
  ) async {
    if (listIds.isEmpty) return {};
    final rows = await (db.select(
      db.localShoppingItems,
    )..where((tbl) => tbl.listId.isIn(listIds) & tbl.deletedAt.isNull())).get();
    final grouped = {
      for (final listId in listIds) listId: <ShoppingItemModel>[],
    };
    for (final row in rows) {
      grouped.putIfAbsent(row.listId, () => <ShoppingItemModel>[]);
      grouped[row.listId]!.add(row.toShoppingItemModel());
    }
    return grouped;
  }

  Future<List<ItemTemplateModel>> getItemTemplates(String homeId) async {
    final rows =
        await (db.select(db.localItemTemplates)
              ..where((tbl) => tbl.homeId.equals(homeId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.usageCount,
                  mode: OrderingMode.desc,
                ),
                (tbl) => OrderingTerm(expression: tbl.name),
              ]))
            .get();
    return rows.map((row) => row.toItemTemplateModel()).toList();
  }

  Future<void> upsertItemTemplates(List<ItemTemplateModel> templates) async {
    if (templates.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localItemTemplates,
        templates.map((template) => template.toLocalCompanion()).toList(),
      );
    });
  }

  Future<String?> _homeIdForList(String listId) async {
    final row = await (db.select(
      db.localShoppingLists,
    )..where((tbl) => tbl.id.equals(listId))).getSingleOrNull();
    return row?.homeId;
  }
}
