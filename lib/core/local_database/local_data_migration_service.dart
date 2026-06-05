import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import 'daos/activity_logs_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/homes_dao.dart';
import 'daos/invitations_dao.dart';
import 'daos/shopping_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/units_dao.dart';
import 'daos/users_dao.dart';
import 'local_database_service.dart';
import 'package:sawa/features/activity_logs/data/models/activity_log_model.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/data/models/unit_model.dart';
import 'package:sawa/features/homes/data/models/home_member_model.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/invitations/data/models/invitation_model.dart';
import 'package:sawa/features/offline_queue/data/datasources/file_queue_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';
import 'local_model_mappers.dart';
import 'package:sawa/features/shopping_lists/data/models/item_template_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';

class LocalDataMigrationResult {
  const LocalDataMigrationResult({
    required this.didRun,
    required this.homes,
    required this.members,
    required this.shoppingLists,
    required this.shoppingItems,
    required this.itemTemplates,
    required this.categories,
    required this.units,
    required this.activityLogs,
    required this.users,
    required this.syncCursors,
    required this.failedKeys,
  });

  final bool didRun;
  final int homes;
  final int members;
  final int shoppingLists;
  final int shoppingItems;
  final int itemTemplates;
  final int categories;
  final int units;
  final int activityLogs;
  final int users;
  final int syncCursors;
  final List<String> failedKeys;

  static const skipped = LocalDataMigrationResult(
    didRun: false,
    homes: 0,
    members: 0,
    shoppingLists: 0,
    shoppingItems: 0,
    itemTemplates: 0,
    categories: 0,
    units: 0,
    activityLogs: 0,
    users: 0,
    syncCursors: 0,
    failedKeys: [],
  );
}

class LocalDataMigrationService {
  LocalDataMigrationService({
    AppDatabase? database,
    SharedPreferences? preferences,
  }) : _db = database ?? LocalDatabaseService.instance,
       _preferences = preferences;

  static const _migrationFlagKey = 'shared_preferences_migration_completed:v2';
  static const _migrationCompletedAtKey =
      'shared_preferences_migration_completed_at:v2';

  final AppDatabase _db;
  final SharedPreferences? _preferences;

  HomesDao get _homesDao => HomesDao(_db);
  ShoppingDao get _shoppingDao => ShoppingDao(_db);
  CategoriesDao get _categoriesDao => CategoriesDao(_db);
  UnitsDao get _unitsDao => UnitsDao(_db);
  UsersDao get _usersDao => UsersDao(_db);
  ActivityLogsDao get _activityLogsDao => ActivityLogsDao(_db);
  SyncDao get _syncDao => SyncDao(_db);

  Future<LocalDataMigrationResult> migrateFromSharedPreferences({
    bool force = false,
  }) async {
    if (!force && await _homesDao.getMeta(_migrationFlagKey) == 'true') {
      return LocalDataMigrationResult.skipped;
    }

    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    final failedKeys = <String>[];

    var homes = 0;
    var members = 0;
    var shoppingLists = 0;
    var shoppingItems = 0;
    var itemTemplates = 0;
    var categories = 0;
    var units = 0;
    var activityLogs = 0;
    var users = 0;
    var syncCursors = 0;

    for (final key in keys) {
      try {
        if (key.startsWith('homes_cache_user:')) {
          final userId = key.substring('homes_cache_user:'.length);
          final migrated = _decodeList(
            prefs.getString(key),
            HomeModel.fromJson,
          );
          await _homesDao.saveUserHomes(userId, migrated);
          homes += migrated.length;

          final activeHomeId = prefs.getString('active_home_user:$userId');
          if (activeHomeId != null && activeHomeId.isNotEmpty) {
            HomeModel? activeHome;
            for (final home in migrated) {
              if (home.id == activeHomeId) {
                activeHome = home;
                break;
              }
            }
            await _homesDao.setActiveHome(
              userId,
              activeHomeId,
              activeHome?.name ?? activeHomeId,
            );
          }
        } else if (key.startsWith('home_members_cache_home:')) {
          final homeId = key.substring('home_members_cache_home:'.length);
          final migrated = _decodeList(
            prefs.getString(key),
            HomeMemberModel.fromJson,
          );
          await _homesDao.saveHomeMembers(homeId, migrated);
          members += migrated.length;
        } else if (key.startsWith('cached_lists_stream_')) {
          final migrated = _decodeList(
            prefs.getString(key),
            ShoppingListModel.fromJson,
          );
          await _shoppingDao.upsertShoppingLists(migrated);
          shoppingLists += migrated.length;
        } else if (key.startsWith('cached_items_stream_')) {
          final listId = key.substring('cached_items_stream_'.length);
          final migrated = _decodeList(
            prefs.getString(key),
            ShoppingItemModel.fromJson,
          );
          await _shoppingDao.upsertShoppingItems(
            listId: listId,
            items: migrated,
          );
          shoppingItems += migrated.length;
        } else if (key.startsWith('cached_templates_')) {
          final migrated = _decodeList(
            prefs.getString(key),
            ItemTemplateModel.fromJson,
          );
          await _shoppingDao.upsertItemTemplates(migrated);
          itemTemplates += migrated.length;
        } else if (key.startsWith('cached_categories_')) {
          final migrated = _decodeList(
            prefs.getString(key),
            CategoryModel.fromJson,
          );
          await _categoriesDao.upsertCategories(migrated);
          categories += migrated.length;
        } else if (key.startsWith('cached_units_')) {
          final migrated = _decodeList(
            prefs.getString(key),
            UnitModel.fromJson,
          );
          await _unitsDao.upsertUnits(migrated);
          units += migrated.length;
        } else if (key.startsWith('cached_activity_logs')) {
          final migrated = _decodeList(
            prefs.getString(key),
            ActivityLogModel.fromJson,
          );
          await _activityLogsDao.upsertActivityLogs(migrated);
          activityLogs += migrated.length;
        } else if (key.endsWith('_cached_profile')) {
          final userId = key.substring(
            0,
            key.length - '_cached_profile'.length,
          );
          final migrated = _decodeObject(
            prefs.getString(key),
            UserModel.fromJson,
          );
          if (userId.isNotEmpty && migrated != null) {
            await _usersDao.upsertUser(migrated, lastSeenAt: DateTime.now());
            users++;
          }
        } else if (key.startsWith('cached_home_invitations_') ||
            key.startsWith('cached_user_invitations_')) {
          final migrated = _decodeList(
            prefs.getString(key),
            InvitationModel.fromJson,
          );
          if (migrated.isNotEmpty) {
            final invitationsDao = InvitationsDao(_db);
            final isUserInvitations = key.startsWith('cached_user_invitations_');
            final cacheUserId = isUserInvitations
                ? key.substring('cached_user_invitations_'.length)
                : null;
            await invitationsDao.upsertInvitations(
              migrated
                  .map((inv) => inv.toLocalRow(userId: cacheUserId))
                  .toList(),
            );
          }
        } else if (key.startsWith('sync_ts_')) {
          final migrated = await _migrateSyncTimestamp(key, prefs);
          if (migrated) syncCursors++;
        }
      } catch (_) {
        failedKeys.add(key);
      }
    }

    try {
      await _migrateFileQueue(prefs);
    } catch (_) {
      failedKeys.add('offline_queue_files');
    }

    await _homesDao.setMeta(_migrationFlagKey, 'true');
    await _homesDao.setMeta(
      _migrationCompletedAtKey,
      DateTime.now().toIso8601String(),
    );

    return LocalDataMigrationResult(
      didRun: true,
      homes: homes,
      members: members,
      shoppingLists: shoppingLists,
      shoppingItems: shoppingItems,
      itemTemplates: itemTemplates,
      categories: categories,
      units: units,
      activityLogs: activityLogs,
      users: users,
      syncCursors: syncCursors,
      failedKeys: failedKeys,
    );
  }

  Future<void> _migrateFileQueue(SharedPreferences prefs) async {
    final userId = prefs.getString('last_logged_in_user_id') ?? 'anonymous';
    final fileQueue = FileQueueDataSource(
      legacyPrefs: prefs,
      userIdProvider: () => userId,
    );

    final entries = <QueueEntry>[];
    for (final status in SyncStatus.values) {
      entries.addAll(await fileQueue.getEntriesByStatus(status));
    }

    final seenKeys = <String>{};
    for (final entry in entries) {
      if (!seenKeys.add(entry.idempotencyKey)) continue;
      await _db
          .into(_db.localPendingMutations)
          .insert(
            LocalPendingMutationsCompanion.insert(
              idempotencyKey: entry.idempotencyKey,
              userId: userId,
              homeId: Value(entry.homeId),
              entityType: entry.entityType.name,
              entityId: entry.entityId,
              operation: entry.actionType.name,
              payloadJson: jsonEncode(entry.payload),
              createdAt: Value(entry.createdAt),
              nextRetryAt: Value(entry.lastRetryAt),
              retryCount: Value(entry.retryCount),
              status: Value(_mutationStatusFromQueueStatus(entry.syncStatus)),
              lastError: Value(entry.errorMessage),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<bool> _migrateSyncTimestamp(
    String key,
    SharedPreferences prefs,
  ) async {
    final rawTime = prefs.getString(key);
    if (rawTime == null || rawTime.isEmpty) return false;

    final parsedTime = DateTime.tryParse(rawTime);
    if (parsedTime == null) return false;

    final parsedKey = _parseSyncTimestampKey(key);
    if (parsedKey == null) return false;

    await _syncDao.updateLocalSyncTime(
      parsedKey.homeId,
      parsedKey.tableName,
      parsedTime,
    );
    return true;
  }

  _ParsedSyncTimestampKey? _parseSyncTimestampKey(String key) {
    final remainder = key.substring('sync_ts_'.length);
    const tableNames = [
      'shopping_lists',
      'shopping_items',
      'home_members',
      'activity_logs',
      'categories',
      'inventory_items',
      'expenses',
      'tasks',
      'units',
      'homes',
    ];

    for (final tableName in tableNames) {
      final suffix = '_$tableName';
      if (remainder.endsWith(suffix)) {
        final homeId = remainder.substring(0, remainder.length - suffix.length);
        if (homeId.isNotEmpty) {
          return _ParsedSyncTimestampKey(homeId, tableName);
        }
      }
    }
    return null;
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final result = <T>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      try {
        result.add(fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }

  T? _decodeObject<T>(
    String? raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;

    return fromJson(Map<String, dynamic>.from(decoded));
  }

  String _mutationStatusFromQueueStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return mutationStatusPending;
      case SyncStatus.syncing:
        return mutationStatusSyncing;
      case SyncStatus.failed:
        return mutationStatusFailed;
    }
  }
}

class _ParsedSyncTimestampKey {
  const _ParsedSyncTimestampKey(this.homeId, this.tableName);

  final String homeId;
  final String tableName;
}
