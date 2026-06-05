import 'package:drift/drift.dart';

import '../app_database.dart';

class MutationsDao {
  MutationsDao(this.db);

  final AppDatabase db;

  Future<int> pendingCount({String? homeId}) async {
    final query = db.select(db.localPendingMutations)
      ..where(
        (tbl) =>
            tbl.status.isIn([mutationStatusPending, mutationStatusFailed]) &
            (homeId == null ? const Constant(true) : tbl.homeId.equals(homeId)),
      );
    final rows = await query.get();
    return rows.length;
  }

  Future<List<LocalPendingMutation>> dueMutations(DateTime now) {
    return (db.select(db.localPendingMutations)
          ..where(
            (tbl) =>
                tbl.status.equals(mutationStatusPending) &
                (tbl.nextRetryAt.isNull() |
                    tbl.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  Future<void> cancelHomeMutations(String homeId) {
    return (db.update(
      db.localPendingMutations,
    )..where((tbl) => tbl.homeId.equals(homeId))).write(
      const LocalPendingMutationsCompanion(
        status: Value(mutationStatusCancelled),
      ),
    );
  }
}
