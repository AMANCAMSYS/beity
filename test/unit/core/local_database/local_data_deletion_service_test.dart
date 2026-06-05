import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/local_data_deletion_service.dart';

void main() {
  final sqliteSkip = _sqliteSkipReason();
  late AppDatabase db;
  late LocalDataDeletionService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = LocalDataDeletionService(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'deleteLocalHomeData removes only the selected home data',
    () async {
      await _insertHomeGraph(db, homeId: 'home-1', listId: 'list-1');
      await _insertHomeGraph(db, homeId: 'home-2', listId: 'list-2');

      await service.deleteLocalHomeData('home-1');

      final deletedHome = await (db.select(
        db.localHomes,
      )..where((tbl) => tbl.id.equals('home-1'))).get();
      final remainingHome = await (db.select(
        db.localHomes,
      )..where((tbl) => tbl.id.equals('home-2'))).get();

      final deletedHomeItems = await (db.select(
        db.localShoppingItems,
      )..where((tbl) => tbl.homeId.equals('home-1'))).get();
      final remainingHomeItems = await (db.select(
        db.localShoppingItems,
      )..where((tbl) => tbl.homeId.equals('home-2'))).get();

      expect(deletedHome, isEmpty);
      expect(deletedHomeItems, isEmpty);
      expect(remainingHome, hasLength(1));
      expect(remainingHomeItems, hasLength(1));
    },
    skip: sqliteSkip ?? false,
  );
}

Future<void> _insertHomeGraph(
  AppDatabase db, {
  required String homeId,
  required String listId,
}) async {
  await db
      .into(db.localHomes)
      .insert(
        LocalHomesCompanion.insert(
          id: homeId,
          name: 'Home $homeId',
          type: 'family',
          ownerId: 'user-1',
        ),
      );
  await db
      .into(db.localHomeMembers)
      .insert(
        LocalHomeMembersCompanion.insert(
          id: 'member-$homeId',
          homeId: homeId,
          userId: 'user-1',
          role: 'owner',
        ),
      );
  await db
      .into(db.localShoppingLists)
      .insert(
        LocalShoppingListsCompanion.insert(
          id: listId,
          homeId: homeId,
          title: 'Groceries',
          createdBy: 'user-1',
        ),
      );
  await db
      .into(db.localShoppingItems)
      .insert(
        LocalShoppingItemsCompanion.insert(
          id: 'item-$homeId',
          listId: listId,
          homeId: homeId,
          name: 'Milk',
          createdBy: 'user-1',
        ),
      );
  await db
      .into(db.localPendingMutations)
      .insert(
        LocalPendingMutationsCompanion.insert(
          idempotencyKey: 'mutation-$homeId',
          userId: 'user-1',
          homeId: Value(homeId),
          entityType: 'shoppingItem',
          entityId: 'item-$homeId',
          operation: 'addItem',
          payloadJson: '{}',
        ),
      );
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
