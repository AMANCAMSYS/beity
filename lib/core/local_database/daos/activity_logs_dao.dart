import 'package:drift/drift.dart';
import 'package:sawa/features/activity_logs/data/models/activity_log_model.dart';
import 'package:sawa/features/activity_logs/domain/entities/activity_log.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class ActivityLogsDao {
  ActivityLogsDao(this.db);

  final AppDatabase db;

  Future<List<ActivityLogModel>> getActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = db.select(db.localActivityLogs)
      ..where(
        (tbl) => _homeActivityPredicate(
          tbl,
          homeId: homeId,
          actorId: actorId,
          actionTypes: actionTypes,
        ),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => row.toActivityLogModel()).toList();
  }

  Stream<List<ActivityLogModel>> watchActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  }) {
    final query = db.select(db.localActivityLogs)
      ..where(
        (tbl) => _homeActivityPredicate(
          tbl,
          homeId: homeId,
          actorId: actorId,
          actionTypes: actionTypes,
        ),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.watch().map(
      (rows) => rows.map((row) => row.toActivityLogModel()).toList(),
    );
  }

  Future<List<ActivityLogModel>> getListActivityLogs({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = db.select(db.localActivityLogs)
      ..where((tbl) => _listActivityPredicate(tbl, homeId, listId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => row.toActivityLogModel()).toList();
  }

  Stream<List<ActivityLogModel>> watchListActivityLogs({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  }) {
    final query = db.select(db.localActivityLogs)
      ..where((tbl) => _listActivityPredicate(tbl, homeId, listId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.watch().map(
      (rows) => rows.map((row) => row.toActivityLogModel()).toList(),
    );
  }

  Future<ActivityLogModel?> getActivityLogById(String id) async {
    final row = await (db.select(
      db.localActivityLogs,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row?.toActivityLogModel();
  }

  Future<void> upsertActivityLogs(List<ActivityLogModel> logs) async {
    if (logs.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localActivityLogs,
        logs.map((log) => log.toLocalCompanion()).toList(),
      );
    });
  }

  Future<void> deleteActivityLog(String id) {
    return (db.delete(
      db.localActivityLogs,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Expression<bool> _homeActivityPredicate(
    LocalActivityLogs tbl, {
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
  }) {
    var predicate = tbl.homeId.equals(homeId);
    if (actorId != null && actorId.isNotEmpty) {
      predicate = predicate & tbl.userId.equals(actorId);
    }
    if (actionTypes != null && actionTypes.isNotEmpty) {
      predicate = predicate & tbl.action.isIn(actionTypes.map((a) => a.value));
    }
    return predicate;
  }

  Expression<bool> _listActivityPredicate(
    LocalActivityLogs tbl,
    String homeId,
    String listId,
  ) {
    final directListEvent =
        tbl.entityType.equals(EntityType.shoppingList.value) &
        tbl.entityId.equals(listId);
    final metadataListEvent =
        tbl.metadataJson.isNotNull() &
        tbl.metadataJson.like('%"list_id":"$listId"%');

    return tbl.homeId.equals(homeId) & (directListEvent | metadataListEvent);
  }
}
