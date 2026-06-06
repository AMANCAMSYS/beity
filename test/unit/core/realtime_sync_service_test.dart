import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sawa/core/services/local_cache_notifier.dart';
import 'package:sawa/core/services/realtime_sync_service.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/features/shopping_lists/data/datasources/shopping_local_datasource.dart';
import 'package:sawa/features/shopping_lists/data/models/item_template_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:sawa/features/inventory/data/models/inventory_item_model.dart';
import 'package:sawa/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:sawa/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:sawa/features/expenses/data/models/expense_model.dart';
import 'package:sawa/features/expenses/presentation/providers/expense_providers.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class FakeRealtimeChannel extends Fake implements RealtimeChannel {}

class MockShoppingLocalDataSource extends Mock
    implements ShoppingLocalDataSource {}

class MockInventoryLocalDataSource extends Mock
    implements InventoryLocalDataSource {}

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient supabaseClient;
  late MockRealtimeChannel channel;
  late MockShoppingLocalDataSource localDataSource;
  late MockInventoryLocalDataSource inventoryLocalDataSource;
  late MockExpenseLocalDataSource expenseLocalDataSource;
  late MockSyncService syncService;
  late Map<String, void Function(PostgresChangePayload)> callbacks;

  setUpAll(() {
    registerFallbackValue(FakeRealtimeChannel());
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(
      PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: 'home-1',
      ),
    );
  });

  setUp(() {
    supabaseClient = MockSupabaseClient();
    channel = MockRealtimeChannel();
    localDataSource = MockShoppingLocalDataSource();
    inventoryLocalDataSource = MockInventoryLocalDataSource();
    expenseLocalDataSource = MockExpenseLocalDataSource();
    syncService = MockSyncService();
    callbacks = <String, void Function(PostgresChangePayload)>{};

    SupabaseService.client = supabaseClient;

    when(() => supabaseClient.channel(any())).thenReturn(channel);
    when(
      () => supabaseClient.removeChannel(any()),
    ).thenAnswer((_) async => 'ok');
    when(
      () => channel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenAnswer((invocation) {
      final table = invocation.namedArguments[#table] as String;
      final callback =
          invocation.namedArguments[#callback]
              as void Function(PostgresChangePayload);
      callbacks[table] = callback;
      return channel;
    });
    when(() => channel.subscribe(any())).thenReturn(channel);

    when(
      () => localDataSource.getShoppingListsStreamCache(
        homeId: any(named: 'homeId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => <ShoppingListModel>[]);
    when(
      () => localDataSource.saveShoppingListsStreamCache(
        homeId: any(named: 'homeId'),
        status: any(named: 'status'),
        lists: any(named: 'lists'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.getShoppingItemsStreamCache(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => <ShoppingItemModel>[]);
    when(
      () => localDataSource.saveShoppingItemsStreamCache(
        listId: any(named: 'listId'),
        items: any(named: 'items'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.getItemTemplates(homeId: any(named: 'homeId')),
    ).thenAnswer((_) async => <ItemTemplateModel>[]);
    when(
      () => localDataSource.saveItemTemplates(
        homeId: any(named: 'homeId'),
        templates: any(named: 'templates'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.getLastLoggedInUserId(),
    ).thenAnswer((_) async => 'user-1');
    when(
      () => inventoryLocalDataSource.getInventoryItemsStreamCache(
        homeId: any(named: 'homeId'),
      ),
    ).thenAnswer((_) async => <InventoryItemModel>[]);
    when(
      () => inventoryLocalDataSource.saveInventoryItemsStreamCache(
        homeId: any(named: 'homeId'),
        items: any(named: 'items'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => expenseLocalDataSource.getExpensesStreamCache(
        homeId: any(named: 'homeId'),
      ),
    ).thenAnswer((_) async => <ExpenseModel>[]);
    when(
      () => expenseLocalDataSource.saveExpensesStreamCache(
        homeId: any(named: 'homeId'),
        expenses: any(named: 'expenses'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => syncService.updateLocalSyncTime(any(), any(), any()),
    ).thenAnswer((_) async {});
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        shoppingLocalDataSourceProvider.overrideWithValue(localDataSource),
        inventoryLocalDataSourceProvider.overrideWithValue(
          inventoryLocalDataSource,
        ),
        expenseLocalDataSourceProvider.overrideWithValue(
          expenseLocalDataSource,
        ),
        syncServiceProvider.overrideWithValue(syncService),
      ],
    );
  }

  test(
    'initBuffered subscribes immediately and flushes events in order',
    () async {
      final savedSnapshots = <List<ShoppingListModel>>[];
      var cachedLists = <ShoppingListModel>[];
      when(
        () => localDataSource.getShoppingListsStreamCache(
          homeId: 'home-1',
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => cachedLists);
      when(
        () => localDataSource.saveShoppingListsStreamCache(
          homeId: 'home-1',
          status: any(named: 'status'),
          lists: any(named: 'lists'),
        ),
      ).thenAnswer((invocation) async {
        final lists =
            invocation.namedArguments[#lists] as List<ShoppingListModel>;
        cachedLists = List<ShoppingListModel>.from(lists);
        savedSnapshots.add(cachedLists);
      });

      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.initBuffered('home-1');

      verify(() => supabaseClient.channel('realtime_sync:home-1')).called(1);
      expect(
        callbacks.keys,
        containsAll(<String>[
          'shopping_lists',
          'shopping_items',
          'tasks',
          'expenses',
          'inventory_items',
          'categories',
          'home_members',
        ]),
      );

      callbacks['shopping_lists']!(_shoppingListPayload('list-1', 'Milk'));
      callbacks['shopping_lists']!(_shoppingListPayload('list-2', 'Bread'));

      expect(service.isBuffering, isTrue);
      expect(service.bufferedEventCount, 2);
      verifyNever(
        () => localDataSource.saveShoppingListsStreamCache(
          homeId: 'home-1',
          status: any(named: 'status'),
          lists: any(named: 'lists'),
        ),
      );

      await service.flushBuffer();

      expect(service.isBuffering, isFalse);
      expect(service.bufferedEventCount, 0);
      expect(savedSnapshots.last.map((list) => list.id), ['list-1', 'list-2']);
    },
  );

  test('resume reconnects a non-subscribed channel live without buffering', () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final service = container.read(realtimeSyncServiceProvider);

    service.init('home-1');
    expect(service.isBuffering, isFalse);

    service.didChangeAppLifecycleState(AppLifecycleState.resumed);

    verify(() => supabaseClient.removeChannel(channel)).called(1);
    verify(() => supabaseClient.channel('realtime_sync:home-1')).called(2);
    expect(service.isBuffering, isFalse);
    expect(service.bufferedEventCount, 0);
  });

  test('shopping item realtime event notifies only the changed list', () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final service = container.read(realtimeSyncServiceProvider);

    service.initBuffered('home-1');

    final eventFuture = LocalCacheNotifier.stream
        .firstWhere((event) => event.entityType == 'shopping_items')
        .timeout(const Duration(seconds: 1));

    callbacks['shopping_items']!(
      _shoppingItemPayload(id: 'item-1', listId: 'list-1', name: 'Milk'),
    );

    await service.flushBuffer();

    final event = await eventFuture;
    expect(event.homeId, 'home-1');
    expect(event.entityType, 'shopping_items');
    expect(event.listId, 'list-1');

    verify(
      () => localDataSource.saveShoppingItemsStreamCache(
        listId: 'list-1',
        items: any(named: 'items'),
      ),
    ).called(1);
    verifyNever(
      () => localDataSource.saveShoppingListsStreamCache(
        homeId: 'home-1',
        status: any(named: 'status'),
        lists: any(named: 'lists'),
      ),
    );
  });

  test(
    'shopping item realtime event from same user still updates cache',
    () async {
      final auth = MockGoTrueClient();
      when(() => supabaseClient.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(
        const User(
          id: 'user-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-31T00:00:00Z',
        ),
      );

      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.initBuffered('home-1');

      callbacks['shopping_items']!(
        _shoppingItemPayload(
          id: 'item-1',
          listId: 'list-1',
          name: 'Milk',
          updatedBy: 'user-1',
        ),
      );

      await service.flushBuffer();

      verify(
        () => localDataSource.saveShoppingItemsStreamCache(
          listId: 'list-1',
          items: any(named: 'items'),
        ),
      ).called(1);
    },
  );

  test(
    'shopping item soft delete realtime event removes item from cache',
    () async {
      final existingItem = ShoppingItemModel(
        id: 'item-1',
        shoppingListId: 'list-1',
        name: 'Milk',
        quantity: 1,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 5, 31, 11),
        updatedAt: DateTime(2026, 5, 31, 11),
      );
      when(
        () => localDataSource.getShoppingItemsStreamCache(listId: 'list-1'),
      ).thenAnswer((_) async => <ShoppingItemModel>[existingItem]);

      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.initBuffered('home-1');
      callbacks['shopping_items']!(
        _shoppingItemPayload(
          id: 'item-1',
          listId: 'list-1',
          name: 'Milk',
          eventType: PostgresChangeEvent.update,
          deletedAt: DateTime(2026, 5, 31, 12),
        ),
      );

      await service.flushBuffer();

      final captured =
          verify(
                () => localDataSource.saveShoppingItemsStreamCache(
                  listId: 'list-1',
                  items: captureAny(named: 'items'),
                ),
              ).captured.single
              as List<ShoppingItemModel>;
      expect(captured, isEmpty);
    },
  );

  test('shopping list realtime events are applied without debounce', () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final service = container.read(realtimeSyncServiceProvider);

    service.init('home-1');
    callbacks['shopping_lists']!(_shoppingListPayload('list-1', 'Milk'));
    await untilCalled(
      () => localDataSource.saveShoppingListsStreamCache(
        homeId: 'home-1',
        status: any(named: 'status'),
        lists: any(named: 'lists'),
      ),
    );

    expect(service.debounceTimerCount, 0);
    verify(
      () => localDataSource.saveShoppingListsStreamCache(
        homeId: 'home-1',
        status: any(named: 'status'),
        lists: any(named: 'lists'),
      ),
    ).called(1);
  });

  test('inventory realtime event notifies inventory item streams', () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final service = container.read(realtimeSyncServiceProvider);

    service.initBuffered('home-1');

    final eventFuture = LocalCacheNotifier.stream
        .firstWhere((event) => event.entityType == 'inventory_items')
        .timeout(const Duration(seconds: 1));

    callbacks['inventory_items']!(_inventoryItemPayload());

    await service.flushBuffer();

    final event = await eventFuture;
    expect(event.homeId, 'home-1');
    expect(event.entityType, 'inventory_items');

    verify(
      () => inventoryLocalDataSource.saveInventoryItemsStreamCache(
        homeId: 'home-1',
        items: any(named: 'items'),
      ),
    ).called(1);
  });

  test('expense realtime event notifies expense streams', () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final service = container.read(realtimeSyncServiceProvider);

    service.initBuffered('home-1');

    final eventFuture = LocalCacheNotifier.stream
        .firstWhere((event) => event.entityType == 'expenses')
        .timeout(const Duration(seconds: 1));

    callbacks['expenses']!(_expensePayload());

    await service.flushBuffer();

    final event = await eventFuture;
    expect(event.homeId, 'home-1');
    expect(event.entityType, 'expenses');

    verify(
      () => expenseLocalDataSource.saveExpensesStreamCache(
        homeId: 'home-1',
        expenses: any(named: 'expenses'),
      ),
    ).called(1);
  });
}

PostgresChangePayload _shoppingListPayload(String id, String title) {
  final now = DateTime(2026, 5, 31, 12);
  return PostgresChangePayload(
    schema: 'public',
    table: 'shopping_lists',
    commitTimestamp: now,
    eventType: PostgresChangeEvent.insert,
    newRecord: <String, dynamic>{
      'id': id,
      'home_id': 'home-1',
      'title': title,
      'type': 'grocery',
      'icon': 'shopping_cart',
      'status': 'active',
      'created_by': 'user-1',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'deleted_at': null,
    },
    oldRecord: const <String, dynamic>{},
    errors: null,
  );
}

PostgresChangePayload _shoppingItemPayload({
  required String id,
  required String listId,
  required String name,
  String? updatedBy,
  PostgresChangeEvent eventType = PostgresChangeEvent.insert,
  DateTime? deletedAt,
}) {
  final now = DateTime(2026, 5, 31, 12);
  return PostgresChangePayload(
    schema: 'public',
    table: 'shopping_items',
    commitTimestamp: now,
    eventType: eventType,
    newRecord: <String, dynamic>{
      'id': id,
      'home_id': 'home-1',
      'list_id': listId,
      'name': name,
      'quantity': 1,
      'purchased_quantity': 0,
      'currency': 'SAR',
      'status': 'pending',
      'created_by': 'user-1',
      'updated_by': updatedBy,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    },
    oldRecord: const <String, dynamic>{},
    errors: null,
  );
}

PostgresChangePayload _inventoryItemPayload() {
  final now = DateTime(2026, 5, 31, 12);
  return PostgresChangePayload(
    schema: 'public',
    table: 'inventory_items',
    commitTimestamp: now,
    eventType: PostgresChangeEvent.update,
    newRecord: <String, dynamic>{
      'id': 'inventory-1',
      'home_id': 'home-1',
      'name': 'Milk',
      'quantity': 4,
      'min_quantity': 1,
      'created_by': 'user-1',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'deleted_at': null,
    },
    oldRecord: const <String, dynamic>{},
    errors: null,
  );
}

PostgresChangePayload _expensePayload() {
  final now = DateTime(2026, 5, 31, 12);
  return PostgresChangePayload(
    schema: 'public',
    table: 'expenses',
    commitTimestamp: now,
    eventType: PostgresChangeEvent.insert,
    newRecord: <String, dynamic>{
      'id': 'expense-1',
      'home_id': 'home-1',
      'amount': 2500,
      'description': 'Groceries',
      'date': now.toIso8601String(),
      'paid_by': 'user-1',
      'currency_code': 'SAR',
      'converted_amount': 2500,
      'created_by': 'user-1',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'deleted_at': null,
    },
    oldRecord: const <String, dynamic>{},
    errors: null,
  );
}
