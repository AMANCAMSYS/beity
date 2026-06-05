import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sawa/features/offline_queue/data/datasources/file_queue_datasource.dart';

import 'app_database.dart';
import 'daos/homes_dao.dart';
import 'daos/mutations_dao.dart';
import 'local_database_service.dart';

class LocalDataDeletionService {
  LocalDataDeletionService({
    AppDatabase? database,
    SharedPreferences? preferences,
  }) : _db = database ?? LocalDatabaseService.instance,
       _preferences = preferences;

  final AppDatabase _db;
  final SharedPreferences? _preferences;

  HomesDao get _homesDao => HomesDao(_db);
  MutationsDao get _mutationsDao => MutationsDao(_db);

  Future<void> deleteLocalHomeData(String homeId) {
    return _homesDao.clearAllHomeData(homeId);
  }

  Future<void> deleteLocalUserData(String userId) async {
    await _homesDao.clearAllUserDataForUser(userId);
    await FileQueueDataSource(
      userIdProvider: () => userId,
    ).clearQueueForUser(userId);
  }

  Future<void> deleteAllLocalData() async {
    await _db.transaction(() async {
      await _db.delete(_db.localPendingMutations).go();
      await _db.delete(_db.localSyncCursors).go();
      await _db.delete(_db.localShoppingModeSessions).go();
      await _db.delete(_db.localActivityLogs).go();
      await _db.delete(_db.localShoppingItems).go();
      await _db.delete(_db.localShoppingLists).go();
      await _db.delete(_db.localItemTemplates).go();
      await _db.delete(_db.localCategories).go();
      await _db.delete(_db.localUnits).go();
      await _db.delete(_db.localHomeMembers).go();
      await _db.delete(_db.localHomes).go();
      await _db.delete(_db.localUsers).go();
      await _db.delete(_db.localStoreMeta).go();
      await _db.delete(_db.localNotifications).go();
      await _db.delete(_db.localNotificationPreferences).go();
      await _db.delete(_db.localInvitations).go();
    });
    await _deleteLegacyQueueDirectory();
  }

  Future<void> deleteTemporaryLocalDataOnly() async {
    await _db.transaction(() async {
      await (_db.delete(_db.localPendingMutations)..where(
            (tbl) => tbl.status.isIn([
              mutationStatusCompleted,
              mutationStatusCancelled,
            ]),
          ))
          .go();
      await (_db.delete(
        _db.localStoreMeta,
      )..where((tbl) => tbl.key.like('temp:%') | tbl.key.like('cache:%'))).go();
    });

    await _deleteLegacySharedPreferenceCaches();
  }

  Future<int> getDatabaseSizeBytes() async {
    final file = await _databaseFile();
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<int> getPendingMutationsCount({String? homeId}) {
    return _mutationsDao.pendingCount(homeId: homeId);
  }

  Future<File> _databaseFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'sawa_local_v1.sqlite'));
  }

  Future<void> _deleteLegacyQueueDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final queueDirectory = Directory(p.join(directory.path, 'offline_queue'));
    if (await queueDirectory.exists()) {
      await queueDirectory.delete(recursive: true);
    }
  }

  Future<void> _deleteLegacySharedPreferenceCaches() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(_isLegacyCacheKey).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  bool _isLegacyCacheKey(String key) {
    return key.startsWith('cached_') ||
        key.startsWith('sync_cache_') ||
        key.startsWith('temp_');
  }
}
