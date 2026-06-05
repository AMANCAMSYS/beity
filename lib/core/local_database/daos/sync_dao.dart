import 'package:drift/drift.dart';

import '../app_database.dart';

class SyncDao {
  SyncDao(this.db);

  final AppDatabase db;

  Future<DateTime> getLocalSyncTime(String homeId, String tableName) async {
    final cursor = await _cursor(homeId, tableName);
    return cursor?.lastServerUpdatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> updateLocalSyncTime(
    String homeId,
    String tableName,
    DateTime time,
  ) async {
    await db
        .into(db.localSyncCursors)
        .insertOnConflictUpdate(
          LocalSyncCursorsCompanion(
            homeId: Value(homeId),
            syncedTableName: Value(tableName),
            lastServerUpdatedAt: Value(time),
            initialSyncDone: const Value(true),
            lastSuccessAt: Value(DateTime.now()),
            lastError: const Value(null),
          ),
        );
  }

  Future<bool> isInitialSyncDone(String homeId, String tableName) async {
    return (await _cursor(homeId, tableName))?.initialSyncDone ?? false;
  }

  Future<void> markInitialSyncDone(String homeId, String tableName) async {
    final existingTime = await getLocalSyncTime(homeId, tableName);
    await updateLocalSyncTime(homeId, tableName, existingTime);
  }

  Future<void> resetLocalSyncTime(String homeId, String tableName) async {
    await db
        .into(db.localSyncCursors)
        .insertOnConflictUpdate(
          LocalSyncCursorsCompanion(
            homeId: Value(homeId),
            syncedTableName: Value(tableName),
            lastServerUpdatedAt: Value(DateTime.fromMillisecondsSinceEpoch(0)),
            initialSyncDone: const Value(false),
            lastAttemptAt: Value(DateTime.now()),
            lastSuccessAt: const Value(null),
            lastError: const Value(null),
          ),
        );
  }

  Future<void> markSyncError(
    String homeId,
    String tableName,
    Object error,
  ) async {
    await db
        .into(db.localSyncCursors)
        .insertOnConflictUpdate(
          LocalSyncCursorsCompanion(
            homeId: Value(homeId),
            syncedTableName: Value(tableName),
            lastAttemptAt: Value(DateTime.now()),
            lastError: Value(error.toString()),
          ),
        );
  }

  Future<LocalSyncCursor?> _cursor(String homeId, String tableName) {
    return (db.select(db.localSyncCursors)..where(
          (tbl) =>
              tbl.homeId.equals(homeId) & tbl.syncedTableName.equals(tableName),
        ))
        .getSingleOrNull();
  }
}
