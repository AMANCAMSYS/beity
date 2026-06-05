import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sawa/features/homes/data/models/home_member_model.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/homes/data/models/home_selection.dart';

import '../app_database.dart';
import '../local_model_mappers.dart';

class HomesDao {
  HomesDao(this.db);

  final AppDatabase db;

  String _homesForUserKey(String userId) => 'homes_for_user:$userId';
  String _activeHomeIdKey(String userId) => 'active_home_id:$userId';
  String _activeHomeNameKey(String userId) => 'active_home_name:$userId';
  String _initialSyncKey(String userId) => 'initial_sync_done:user:$userId';
  String _homeInitialSyncKey(String homeId) => 'initial_sync_done:home:$homeId';

  Future<void> saveUserHomes(String userId, List<HomeModel> homes) async {
    final sorted = sortAvailableHomesByNewest(homes);
    await db.transaction(() async {
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          db.localHomes,
          sorted.map((home) => home.toLocalCompanion()).toList(),
        );
      });
      await setMeta(
        _homesForUserKey(userId),
        jsonEncode(sorted.map((home) => home.id).toList()),
        userId: userId,
      );
    });
  }

  Future<List<HomeModel>> getUserHomes(String userId) async {
    final ids = await _homeIdsForUser(userId);
    if (ids.isEmpty) return [];

    final rows = await (db.select(
      db.localHomes,
    )..where((tbl) => tbl.id.isIn(ids) & tbl.deletedAt.isNull())).get();
    final order = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    final homes = rows.map((row) => row.toHomeModel()).toList()
      ..sort((a, b) => (order[a.id] ?? 0).compareTo(order[b.id] ?? 0));
    return sortAvailableHomesByNewest(homes);
  }

  Stream<List<HomeModel>> watchUserHomes(String userId) {
    return db
        .select(db.localHomes)
        .watch()
        .asyncMap((_) => getUserHomes(userId));
  }

  Future<void> saveHomeMembers(
    String homeId,
    List<HomeMemberModel> members,
  ) async {
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localHomeMembers,
        members.map((member) => member.toLocalCompanion()).toList(),
      );
    });
  }

  Future<List<HomeMemberModel>> getHomeMembers(String homeId) async {
    final rows =
        await (db.select(db.localHomeMembers)..where(
              (tbl) =>
                  tbl.homeId.equals(homeId) &
                  tbl.status.equals('active') &
                  tbl.deletedAt.isNull(),
            ))
            .get();
    return rows.map((row) => row.toHomeMemberModel()).toList();
  }

  Stream<List<HomeMemberModel>> watchHomeMembers(String homeId) {
    final query = db.select(db.localHomeMembers)
      ..where(
        (tbl) =>
            tbl.homeId.equals(homeId) &
            tbl.status.equals('active') &
            tbl.deletedAt.isNull(),
      );
    return query.watch().map(
      (rows) => rows.map((row) => row.toHomeMemberModel()).toList(),
    );
  }

  Future<void> clearHomeMembers(String homeId) async {
    await (db.delete(
      db.localHomeMembers,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
  }

  Future<void> setActiveHome(String userId, String homeId, String homeName) {
    return db.transaction(() async {
      await setMeta(
        _activeHomeIdKey(userId),
        homeId,
        userId: userId,
        homeId: homeId,
      );
      await setMeta(
        _activeHomeNameKey(userId),
        homeName,
        userId: userId,
        homeId: homeId,
      );
      await (db.update(db.localHomes)..where((tbl) => tbl.id.equals(homeId)))
          .write(LocalHomesCompanion(lastOpenedAt: Value(DateTime.now())));
    });
  }

  Future<String?> getActiveHomeIdForUser(String userId) async {
    return getMeta(_activeHomeIdKey(userId));
  }

  Future<String?> getActiveHomeNameForUser(String userId) async {
    return getMeta(_activeHomeNameKey(userId));
  }

  Future<void> clearActiveHome(String userId) async {
    await (db.delete(db.localStoreMeta)..where(
          (tbl) =>
              tbl.key.equals(_activeHomeIdKey(userId)) |
              tbl.key.equals(_activeHomeNameKey(userId)),
        ))
        .go();
  }

  Future<void> setInitialSyncCompleted(String userId, bool completed) {
    return setMeta(
      _initialSyncKey(userId),
      completed.toString(),
      userId: userId,
    );
  }

  Future<bool> isInitialSyncCompleted(String userId) async {
    return (await getMeta(_initialSyncKey(userId))) == 'true';
  }

  Future<void> setHomeInitialSyncCompleted(String homeId, bool completed) {
    return setMeta(
      _homeInitialSyncKey(homeId),
      completed.toString(),
      homeId: homeId,
    );
  }

  Future<bool> isHomeInitialSyncCompleted(String homeId) async {
    return (await getMeta(_homeInitialSyncKey(homeId))) == 'true';
  }

  Future<void> clearAllHomeData(String homeId) async {
    await db.transaction(() async {
      await _clearHomeDataUnlocked(homeId);
    });
  }

  Future<void> clearAllUserDataForUser(String userId) async {
    final homeIds = await _homeIdsForUser(userId);
    await db.transaction(() async {
      for (final homeId in homeIds) {
        await _clearHomeDataUnlocked(homeId);
      }
      await (db.delete(
        db.localStoreMeta,
      )..where((tbl) => tbl.userId.equals(userId))).go();
      await (db.delete(
        db.localUsers,
      )..where((tbl) => tbl.id.equals(userId))).go();
      await (db.delete(
        db.localPendingMutations,
      )..where((tbl) => tbl.userId.equals(userId))).go();
      await (db.delete(
        db.localNotifications,
      )..where((tbl) => tbl.userId.equals(userId))).go();
      await (db.delete(
        db.localNotificationPreferences,
      )..where((tbl) => tbl.userId.equals(userId))).go();
      await (db.delete(
        db.localInvitations,
      )..where((tbl) => tbl.userId.equals(userId))).go();
    });
  }

  Future<void> _clearHomeDataUnlocked(String homeId) async {
    await (db.delete(
      db.localHomeMembers,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localShoppingItems,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localShoppingLists,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localItemTemplates,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localCategories,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localActivityLogs,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localShoppingModeSessions,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localSyncCursors,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localPendingMutations,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localStoreMeta,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localNotifications,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localNotificationPreferences,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localInvitations,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
    await (db.delete(
      db.localHomes,
    )..where((tbl) => tbl.id.equals(homeId))).go();
  }

  Future<void> setMeta(
    String key,
    String value, {
    String? userId,
    String? homeId,
  }) async {
    await db
        .into(db.localStoreMeta)
        .insertOnConflictUpdate(
          LocalStoreMetaCompanion(
            key: Value(key),
            value: Value(value),
            userId: Value(userId),
            homeId: Value(homeId),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<String?> getMeta(String key) async {
    final row = await (db.select(
      db.localStoreMeta,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<List<String>> _homeIdsForUser(String userId) async {
    final raw = await getMeta(_homesForUserKey(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }
}
