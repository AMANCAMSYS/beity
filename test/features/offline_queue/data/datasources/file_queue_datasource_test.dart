import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/offline_queue/data/datasources/file_queue_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/sync_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sawa_queue_test_');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  FileQueueDataSource dataSourceForUser(String userId) {
    return FileQueueDataSource(
      baseDirectoryProvider: () async => tempDir,
      userIdProvider: () => userId,
    );
  }

  FileQueueDataSource dataSourceForUserAtFixedTime(String userId) {
    return FileQueueDataSource(
      baseDirectoryProvider: () async => tempDir,
      userIdProvider: () => userId,
      now: () => DateTime(2026),
    );
  }

  test('persists queue entries outside SharedPreferences', () async {
    final dataSource = dataSourceForUser('user-1');

    await dataSource.enqueueAction(
      actionType: ActionType.addItem,
      entityType: EntityType.shoppingItem,
      entityId: 'item-1',
      homeId: 'home-1',
      payload: {'name': 'Milk'},
    );

    final reloadedDataSource = dataSourceForUser('user-1');
    final entries = await reloadedDataSource.getEntriesByHome('home-1');

    expect(entries, hasLength(1));
    expect(entries.single.entityId, 'item-1');
    expect(entries.single.payload['name'], 'Milk');
  });

  test('serializes concurrent enqueues without losing entries', () async {
    final dataSource = dataSourceForUser('user-1');

    await Future.wait(
      List.generate(25, (index) {
        return dataSource.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-$index',
          homeId: 'home-1',
          payload: {'name': 'Item $index'},
        );
      }),
    );

    final entries = await dataSource.getEntriesByHome('home-1');

    expect(entries, hasLength(25));
    expect(entries.map((entry) => entry.entityId).toSet(), hasLength(25));
  });

  test('generates unique entry ids when clock microseconds collide', () async {
    final dataSource = dataSourceForUserAtFixedTime('user-1');

    final ids = await Future.wait(
      List.generate(5, (index) {
        return dataSource.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: 'item-$index',
          homeId: 'home-1',
          payload: {'name': 'Item $index'},
        );
      }),
    );

    final entries = await dataSource.getEntriesByHome('home-1');

    expect(ids.toSet(), hasLength(5));
    expect(entries.map((entry) => entry.id).toSet(), hasLength(5));
    expect(entries, hasLength(5));
  });

  test('serializes concurrent enqueues across datasource instances', () async {
    final firstInstance = dataSourceForUser('user-1');
    final secondInstance = dataSourceForUser('user-1');

    await Future.wait([
      ...List.generate(15, (index) {
        return firstInstance.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: 'first-$index',
          homeId: 'home-1',
          payload: {'name': 'First $index'},
        );
      }),
      ...List.generate(15, (index) {
        return secondInstance.enqueueAction(
          actionType: ActionType.addItem,
          entityType: EntityType.shoppingItem,
          entityId: 'second-$index',
          homeId: 'home-1',
          payload: {'name': 'Second $index'},
        );
      }),
    ]);

    final entries = await dataSourceForUser(
      'user-1',
    ).getEntriesByHome('home-1');

    expect(entries, hasLength(30));
    expect(entries.map((entry) => entry.entityId).toSet(), hasLength(30));
  });

  test('does not lose a new add while sync deletes an older entry', () async {
    final syncInstance = dataSourceForUser('user-1');
    final uiInstance = dataSourceForUser('user-1');
    final oldEntryId = await syncInstance.enqueueAction(
      actionType: ActionType.updateItem,
      entityType: EntityType.shoppingItem,
      entityId: 'old-item',
      homeId: 'home-1',
      payload: {'name': 'Old'},
    );

    await Future.wait([
      syncInstance.deleteEntry(oldEntryId),
      uiInstance.enqueueAction(
        actionType: ActionType.addItem,
        entityType: EntityType.shoppingItem,
        entityId: 'new-item',
        homeId: 'home-1',
        payload: {'name': 'New'},
      ),
    ]);

    final entries = await dataSourceForUser(
      'user-1',
    ).getEntriesByHome('home-1');

    expect(entries.map((entry) => entry.entityId), contains('new-item'));
    expect(entries.map((entry) => entry.entityId), isNot(contains('old-item')));
  });

  test('keeps queue entries scoped by user', () async {
    await dataSourceForUser('user-1').enqueueAction(
      actionType: ActionType.addItem,
      entityType: EntityType.shoppingItem,
      entityId: 'item-1',
      homeId: 'home-1',
      payload: const {},
    );
    await dataSourceForUser('user-2').enqueueAction(
      actionType: ActionType.addItem,
      entityType: EntityType.shoppingItem,
      entityId: 'item-2',
      homeId: 'home-1',
      payload: const {},
    );

    final user1Entries = await dataSourceForUser(
      'user-1',
    ).getEntriesByHome('home-1');
    final user2Entries = await dataSourceForUser(
      'user-2',
    ).getEntriesByHome('home-1');

    expect(user1Entries.single.entityId, 'item-1');
    expect(user2Entries.single.entityId, 'item-2');
  });

  test('migrates existing SharedPreferences queue once', () async {
    final legacyEntry = QueueEntry(
      id: 1,
      actionType: ActionType.updateItem,
      entityType: EntityType.shoppingItem,
      entityId: 'item-1',
      homeId: 'home-1',
      payload: {'name': 'Bread'},
      createdAt: DateTime(2026),
      syncStatus: SyncStatus.pending,
    );
    SharedPreferences.setMockInitialValues({
      'user-1_offline_queue_entries': jsonEncode([legacyEntry.toJson()]),
    });

    final prefs = await SharedPreferences.getInstance();
    final dataSource = FileQueueDataSource(
      baseDirectoryProvider: () async => tempDir,
      legacyPrefs: prefs,
      userIdProvider: () => 'user-1',
    );

    final entries = await dataSource.getEntriesByHome('home-1');

    expect(entries, hasLength(1));
    expect(entries.single.entityId, 'item-1');
    expect(prefs.getString('user-1_offline_queue_entries'), isNull);
  });

  test('migrates previous aggregate file queue format', () async {
    final legacyEntry = QueueEntry(
      id: 2,
      actionType: ActionType.addItem,
      entityType: EntityType.shoppingItem,
      entityId: 'legacy-item',
      homeId: 'home-1',
      payload: {'name': 'Rice'},
      createdAt: DateTime(2026),
      syncStatus: SyncStatus.pending,
    );
    final legacyDirectory = Directory('${tempDir.path}/offline_queue');
    await legacyDirectory.create(recursive: true);
    final legacyFile = File('${legacyDirectory.path}/user-1.json');
    await legacyFile.writeAsString(
      jsonEncode({
        'version': 1,
        'userId': 'user-1',
        'entries': [legacyEntry.toJson()],
      }),
      flush: true,
    );

    final entries = await dataSourceForUser(
      'user-1',
    ).getEntriesByHome('home-1');

    expect(entries, hasLength(1));
    expect(entries.single.entityId, 'legacy-item');
    expect(await legacyFile.exists(), false);
  });
}
