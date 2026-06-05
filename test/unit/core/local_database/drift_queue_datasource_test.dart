import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/features/offline_queue/data/datasources/drift_queue_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';

void main() {
  final sqliteSkip = _sqliteSkipReason();
  late AppDatabase db;
  late DriftQueueDataSource dataSource;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 1, 1, 10);
    db = AppDatabase(NativeDatabase.memory());
    dataSource = DriftQueueDataSource(
      database: db,
      userIdProvider: () => 'user-1',
      now: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('persists queued actions in local_pending_mutations', () async {
    final id = await dataSource.enqueueAction(
      actionType: ActionType.addItem,
      entityType: EntityType.shoppingItem,
      entityId: 'item-1',
      homeId: 'home-1',
      payload: {'id': 'item-1', 'name': 'Milk'},
    );

    expect(await dataSource.getPendingCount('home-1'), 1);

    final entry = await dataSource.getEntryById(id);
    expect(entry, isNotNull);
    expect(entry!.actionType, ActionType.addItem);
    expect(entry.entityType, EntityType.shoppingItem);
    expect(entry.payload['name'], 'Milk');

    await dataSource.updateEntryStatus(
      entryId: id,
      status: SyncStatus.failed,
      errorMessage: 'network',
    );

    final failed = await dataSource.getFailedEntries('home-1');
    expect(failed, hasLength(1));
    expect(failed.single.retryCount, 1);
    expect(failed.single.errorMessage, 'network');

    await dataSource.deleteEntry(id);
    expect(await dataSource.getEntriesByHome('home-1'), isEmpty);
  }, skip: sqliteSkip ?? false);
}

String? _sqliteSkipReason() {
  if (!Platform.isLinux) return null;
  try {
    DynamicLibrary.open('libsqlite3.so');
    return null;
  } catch (_) {
    return 'libsqlite3.so is not available in this test environment';
  }
}
