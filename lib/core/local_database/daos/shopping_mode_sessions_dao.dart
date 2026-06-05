import 'package:drift/drift.dart';
import 'package:sawa/features/shopping_mode/data/models/shopping_mode_session_model.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class ShoppingModeSessionsDao {
  ShoppingModeSessionsDao(this.db);

  final AppDatabase db;

  Future<ShoppingModeSessionModel?> getActiveSession({
    required String userId,
    required String listId,
  }) async {
    final row =
        await (db.select(db.localShoppingModeSessions)
              ..where(
                (tbl) =>
                    tbl.userId.equals(userId) &
                    tbl.shoppingListId.equals(listId) &
                    tbl.endedAt.isNull(),
              )
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.startedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.toShoppingModeSessionModel();
  }

  Future<ShoppingModeSessionModel?> getActiveSessionForUser(
    String userId,
  ) async {
    final row =
        await (db.select(db.localShoppingModeSessions)
              ..where((tbl) => tbl.userId.equals(userId) & tbl.endedAt.isNull())
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.startedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.toShoppingModeSessionModel();
  }

  Future<ShoppingModeSessionModel?> getSession(String sessionId) async {
    final row = await (db.select(
      db.localShoppingModeSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).getSingleOrNull();
    return row?.toShoppingModeSessionModel();
  }

  Future<void> upsertSession(
    ShoppingModeSessionModel session, {
    String localState = localStateSynced,
  }) {
    return db
        .into(db.localShoppingModeSessions)
        .insertOnConflictUpdate(
          session.toLocalCompanion(localState: localState),
        );
  }

  Future<ShoppingModeSessionModel?> endSessionLocally({
    required String sessionId,
    required int itemsPurchasedCount,
    required DateTime endedAt,
    String localState = localStatePendingUpdate,
  }) async {
    await (db.update(
      db.localShoppingModeSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).write(
      LocalShoppingModeSessionsCompanion(
        endedAt: Value(endedAt),
        itemsPurchasedCount: Value(itemsPurchasedCount),
        updatedAt: Value(endedAt),
        localState: Value(localState),
      ),
    );
    return getSession(sessionId);
  }

  Future<void> deleteSession(String sessionId) {
    return (db.delete(
      db.localShoppingModeSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).go();
  }
}
