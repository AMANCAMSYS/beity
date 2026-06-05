import 'package:drift/drift.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class UsersDao {
  UsersDao(this.db);

  final AppDatabase db;

  Future<void> upsertUser(UserModel user, {DateTime? lastSeenAt}) {
    return db
        .into(db.localUsers)
        .insertOnConflictUpdate(user.toLocalCompanion(lastSeenAt: lastSeenAt));
  }

  Future<UserModel?> getUser(String userId) async {
    final row = await (db.select(
      db.localUsers,
    )..where((tbl) => tbl.id.equals(userId))).getSingleOrNull();
    return row?.toUserModel();
  }

  Stream<UserModel?> watchUser(String userId) {
    return (db.select(db.localUsers)..where((tbl) => tbl.id.equals(userId)))
        .watchSingleOrNull()
        .map((row) => row?.toUserModel());
  }

  Future<void> updateLastSeen(String userId, DateTime lastSeenAt) {
    return (db.update(db.localUsers)..where((tbl) => tbl.id.equals(userId)))
        .write(LocalUsersCompanion(lastSeenAt: Value(lastSeenAt)));
  }

  Future<void> deleteUser(String userId) {
    return (db.delete(
      db.localUsers,
    )..where((tbl) => tbl.id.equals(userId))).go();
  }
}
