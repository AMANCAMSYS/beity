import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/services/realtime_sync_service.dart';
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

  group('T062: Realtime reconnect after app pause', () {
    test('resume reconnects channel and re-subscribes to all tables', () {
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

    test('resume does nothing when no homeId is set', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      verifyNever(() => supabaseClient.channel(any()));
    });

    test('resume ignores non-resumed lifecycle states', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.init('home-1');
      clearInteractions(supabaseClient);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      service.didChangeAppLifecycleState(AppLifecycleState.detached);

      verifyNever(() => supabaseClient.removeChannel(any()));
      verifyNever(() => supabaseClient.channel(any()));
    });

    test(
      'buffered init subscribes immediately and flushes events after resume',
      () async {
        final container = buildContainer();
        addTearDown(container.dispose);
        final service = container.read(realtimeSyncServiceProvider);

        service.initBuffered('home-1');
        expect(service.isBuffering, isTrue);

        callbacks['shopping_lists']!(_shoppingListPayload('list-1', 'Milk'));
        callbacks['shopping_lists']!(_shoppingListPayload('list-2', 'Bread'));

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

        verify(
          () => localDataSource.saveShoppingListsStreamCache(
            homeId: 'home-1',
            status: any(named: 'status'),
            lists: any(named: 'lists'),
          ),
        ).called(greaterThan(0));
      },
    );

    test(
      'shopping item events after reconnect update correct list cache',
      () async {
        final container = buildContainer();
        addTearDown(container.dispose);
        final service = container.read(realtimeSyncServiceProvider);

        service.init('home-1');

        service.didChangeAppLifecycleState(AppLifecycleState.resumed);

        callbacks['shopping_items']!(
          _shoppingItemPayload(
            id: 'item-after-reconnect',
            listId: 'list-1',
            name: 'Post-Reconnect Item',
          ),
        );

        await untilCalled(
          () => localDataSource.saveShoppingItemsStreamCache(
            listId: 'list-1',
            items: any(named: 'items'),
          ),
        );

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
      },
    );

    test('multiple pause/resume cycles each trigger a fresh reconnect', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.init('home-1');

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      verify(() => supabaseClient.removeChannel(channel)).called(3);
      verify(() => supabaseClient.channel('realtime_sync:home-1')).called(4);
    });

    test('unsubscribe clears state and prevents further event processing', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final service = container.read(realtimeSyncServiceProvider);

      service.init('home-1');
      service.unsubscribe();

      verify(() => supabaseClient.removeChannel(channel)).called(1);

      callbacks['shopping_lists']!(_shoppingListPayload('list-1', 'Milk'));

      verifyNever(
        () => localDataSource.saveShoppingListsStreamCache(
          homeId: any(named: 'homeId'),
          status: any(named: 'status'),
          lists: any(named: 'lists'),
        ),
      );
    });
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
}) {
  final now = DateTime(2026, 5, 31, 12);
  return PostgresChangePayload(
    schema: 'public',
    table: 'shopping_items',
    commitTimestamp: now,
    eventType: PostgresChangeEvent.insert,
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
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'deleted_at': null,
    },
    oldRecord: const <String, dynamic>{},
    errors: null,
  );
}
