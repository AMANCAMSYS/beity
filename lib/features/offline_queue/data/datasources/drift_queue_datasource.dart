import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/sync_status.dart';
import 'queue_datasource.dart';

class DriftQueueDataSource implements QueueDataSource {
  DriftQueueDataSource({
    AppDatabase? database,
    String Function()? userIdProvider,
    DateTime Function()? now,
  }) : _db = database ?? LocalDatabaseService.instance,
       _now = now ?? DateTime.now,
       _userIdProvider =
           userIdProvider ??
           (() {
             final user = SupabaseService.client.auth.currentUser;
             if (user != null) return user.id;
             try {
               return AppPreferences.instance.getString(
                     'last_logged_in_user_id',
                   ) ??
                   'anonymous';
             } catch (_) {
               return 'anonymous';
             }
           });

  final AppDatabase _db;
  final String Function() _userIdProvider;
  final DateTime Function() _now;

  String get _userId => _userIdProvider();

  @override
  Future<void> clearQueue() {
    return clearQueueForUser(_userId);
  }

  @override
  Future<void> clearQueueForUser(String userId) {
    return (_db.delete(
      _db.localPendingMutations,
    )..where((tbl) => tbl.userId.equals(userId))).go();
  }

  @override
  Future<int> enqueueAction({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    String? homeId,
    MutationScope scope = MutationScope.home,
    required Map<String, dynamic> payload,
  }) async {
    final entry = QueueEntry(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      homeId: homeId,
      scope: scope,
      payload: payload,
      createdAt: _now(),
      syncStatus: SyncStatus.pending,
    );

    return _db
        .into(_db.localPendingMutations)
        .insert(
          LocalPendingMutationsCompanion.insert(
            idempotencyKey: entry.idempotencyKey,
            userId: _userId,
            homeId: Value(homeId),
            scope: Value(scope.name),
            entityType: entityType.name,
            entityId: entityId,
            operation: actionType.name,
            payloadJson: jsonEncode(payload),
            baseUpdatedAt: Value(_parseDateTime(payload['base_updated_at'])),
            createdAt: Value(entry.createdAt),
            status: const Value(mutationStatusPending),
          ),
        );
  }

  @override
  Future<List<QueueEntry>> getEntriesByHome(String homeId) async {
    final rows =
        await (_db.select(_db.localPendingMutations)
              ..where(
                (tbl) =>
                    tbl.userId.equals(_userId) &
                    tbl.scope.equals(MutationScope.home.name) &
                    tbl.homeId.equals(homeId) &
                    tbl.status.isIn([
                      mutationStatusPending,
                      mutationStatusSyncing,
                      mutationStatusFailed,
                    ]),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
            .get();
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<List<QueueEntry>> getEntriesByUserScope(String userId) async {
    final rows =
        await (_db.select(_db.localPendingMutations)
              ..where(
                (tbl) =>
                    tbl.userId.equals(userId) &
                    tbl.scope.equals('user') &
                    tbl.status.isIn([
                      mutationStatusPending,
                      mutationStatusSyncing,
                      mutationStatusFailed,
                    ]),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
            .get();
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<List<QueueEntry>> getEntriesByGlobalScope() async {
    final rows =
        await (_db.select(_db.localPendingMutations)
              ..where(
                (tbl) =>
                    tbl.userId.equals(_userId) &
                    tbl.scope.equals('global') &
                    tbl.status.isIn([
                      mutationStatusPending,
                      mutationStatusSyncing,
                      mutationStatusFailed,
                    ]),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
            .get();
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<List<QueueEntry>> getEntriesByStatus(SyncStatus status) async {
    final rows =
        await (_db.select(_db.localPendingMutations)
              ..where(
                (tbl) =>
                    tbl.userId.equals(_userId) &
                    tbl.status.equals(_mutationStatusFromSyncStatus(status)),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
            .get();
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<int> getPendingCount(String homeId) async {
    final rows =
        await (_db.select(_db.localPendingMutations)..where(
              (tbl) =>
                  tbl.userId.equals(_userId) &
                  tbl.scope.equals(MutationScope.home.name) &
                  tbl.homeId.equals(homeId) &
                  tbl.status.equals(mutationStatusPending),
            ))
            .get();
    return rows.length;
  }

  @override
  Future<int> getPendingCountForUser(String userId) async {
    final rows =
        await (_db.select(_db.localPendingMutations)..where(
              (tbl) =>
                  tbl.userId.equals(userId) &
                  tbl.scope.isIn([
                    MutationScope.user.name,
                    MutationScope.global.name,
                  ]) &
                  tbl.status.equals(mutationStatusPending),
            ))
            .get();
    return rows.length;
  }

  @override
  Future<QueueEntry?> getEntryById(int id) async {
    final row =
        await (_db.select(_db.localPendingMutations)
              ..where((tbl) => tbl.id.equals(id) & tbl.userId.equals(_userId)))
            .getSingleOrNull();
    return row == null ? null : _entryFromRow(row);
  }

  @override
  Future<void> updateEntryStatus({
    required int entryId,
    required SyncStatus status,
    String? errorMessage,
  }) async {
    final existing = await (_db.select(
      _db.localPendingMutations,
    )..where((tbl) => tbl.id.equals(entryId))).getSingleOrNull();
    if (existing == null) return;

    final nextRetryCount = status == SyncStatus.failed
        ? existing.retryCount + 1
        : existing.retryCount;
    await (_db.update(
      _db.localPendingMutations,
    )..where((tbl) => tbl.id.equals(entryId))).write(
      LocalPendingMutationsCompanion(
        status: Value(_mutationStatusFromSyncStatus(status)),
        retryCount: Value(nextRetryCount),
        lastError: Value(errorMessage),
        nextRetryAt: Value(
          status == SyncStatus.failed
              ? _nextRetryAt(nextRetryCount)
              : status == SyncStatus.syncing
              ? _now()
              : null,
        ),
      ),
    );
  }

  @override
  Future<void> deleteEntry(int entryId) {
    return (_db.delete(
      _db.localPendingMutations,
    )..where((tbl) => tbl.id.equals(entryId))).go();
  }

  @override
  Future<void> deleteCompletedEntries(String homeId) {
    return (_db.delete(_db.localPendingMutations)..where(
          (tbl) =>
              tbl.userId.equals(_userId) &
              tbl.scope.equals(MutationScope.home.name) &
              tbl.homeId.equals(homeId),
        ))
        .go();
  }

  @override
  Future<List<QueueEntry>> getFailedEntries(String homeId) async {
    final rows =
        await (_db.select(_db.localPendingMutations)
              ..where(
                (tbl) =>
                    tbl.userId.equals(_userId) &
                    tbl.scope.equals(MutationScope.home.name) &
                    tbl.homeId.equals(homeId) &
                    tbl.status.equals(mutationStatusFailed),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
            .get();
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<void> resetProcessingToPending(String homeId) {
    return (_db.update(_db.localPendingMutations)..where(
          (tbl) =>
              tbl.userId.equals(_userId) &
              tbl.scope.equals(MutationScope.home.name) &
              tbl.homeId.equals(homeId) &
              tbl.status.equals(mutationStatusSyncing),
        ))
        .write(
          const LocalPendingMutationsCompanion(
            status: Value(mutationStatusPending),
            nextRetryAt: Value(null),
          ),
        );
  }

  @override
  Future<void> resetProcessingToPendingForUserScope(String userId) {
    return (_db.update(_db.localPendingMutations)..where(
          (tbl) =>
              tbl.userId.equals(userId) &
              tbl.scope.isIn([
                MutationScope.user.name,
                MutationScope.global.name,
              ]) &
              tbl.status.equals(mutationStatusSyncing),
        ))
        .write(
          const LocalPendingMutationsCompanion(
            status: Value(mutationStatusPending),
            nextRetryAt: Value(null),
          ),
        );
  }

  QueueEntry _entryFromRow(LocalPendingMutation row) {
    return QueueEntry(
      id: row.id,
      actionType: _actionTypeFromOperation(row.operation),
      entityType: _entityTypeFromValue(row.entityType),
      entityId: row.entityId,
      homeId: row.homeId,
      scope: _parseScope(row.scope),
      payload: _decodePayload(row.payloadJson),
      createdAt: row.createdAt,
      syncStatus: _syncStatusFromMutationStatus(row.status),
      retryCount: row.retryCount,
      lastRetryAt: row.nextRetryAt,
      errorMessage: row.lastError,
      idempotencyKey: row.idempotencyKey,
    );
  }

  MutationScope _parseScope(String value) {
    for (final s in MutationScope.values) {
      if (s.name == value) return s;
    }
    return MutationScope.home;
  }

  Map<String, dynamic> _decodePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  ActionType _actionTypeFromOperation(String value) {
    for (final actionType in ActionType.values) {
      if (actionType.name == value) return actionType;
    }
    switch (value) {
      case operationInsert:
        return ActionType.addItem;
      case operationUpdate:
        return ActionType.updateItem;
      case operationDelete:
        return ActionType.deleteItem;
      case operationRestore:
        return ActionType.restoreItem;
      default:
        return ActionType.updateItem;
    }
  }

  EntityType _entityTypeFromValue(String value) {
    for (final entityType in EntityType.values) {
      if (entityType.name == value || entityType.tableName == value) {
        return entityType;
      }
    }
    return EntityType.shoppingItem;
  }

  String _mutationStatusFromSyncStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return mutationStatusPending;
      case SyncStatus.syncing:
        return mutationStatusSyncing;
      case SyncStatus.failed:
        return mutationStatusFailed;
    }
  }

  SyncStatus _syncStatusFromMutationStatus(String status) {
    switch (status) {
      case mutationStatusPending:
        return SyncStatus.pending;
      case mutationStatusSyncing:
        return SyncStatus.syncing;
      case mutationStatusFailed:
        return SyncStatus.failed;
      default:
        return SyncStatus.failed;
    }
  }

  DateTime _nextRetryAt(int retryCount) {
    final seconds = math.min(300, math.pow(2, retryCount).toInt() * 2);
    return _now().add(Duration(seconds: seconds));
  }

  DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
