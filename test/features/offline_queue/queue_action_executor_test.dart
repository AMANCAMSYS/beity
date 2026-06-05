import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/features/offline_queue/data/datasources/queue_action_executor.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class FakePostgrestMaybeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  FakePostgrestMaybeSingleBuilder([this.row]);

  final PostgrestMap? row;

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) async {
    return onValue(row);
  }
}

class FakePostgrestSelectBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  FakePostgrestSelectBuilder([this.maybeSingleRow]);

  final PostgrestMap? maybeSingleRow;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return FakePostgrestMaybeSingleBuilder(maybeSingleRow);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakePostgrestFilterBuilder([this.maybeSingleRow]);

  final PostgrestMap? maybeSingleRow;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) {
    return FakePostgrestSelectBuilder(maybeSingleRow);
  }

  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue([]);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic> capturedUpdates = {};
  final Map<String, dynamic> capturedUpserts = {};

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(
    Map values, {
    Object? returning,
  }) {
    capturedUpdates.addAll(values.cast<String, dynamic>());
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    if (values is Map) {
      capturedUpserts.addAll(values.cast<String, dynamic>());
    }
    return FakePostgrestFilterBuilder();
  }
}

void main() {
  group('QueueActionExecutor', () {
    test('updateItem action maps purchased_quantity correctly', () async {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(
        const User(
          id: 'user_123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-31T00:00:00Z',
        ),
      );

      // When from() is called, return our fake query builder for shopping_items,
      // and throw an exception for sync_operations_log to skip the idempotency checks.
      when(() => mockClient.from(any())).thenAnswer((invocation) {
        final table = invocation.positionalArguments[0] as String;
        if (table == 'sync_operations_log') {
          throw Exception(
            'Simulated missing log table to skip idempotency checks',
          );
        }
        return fakeQueryBuilder;
      });

      final executor = QueueActionExecutor(mockClient);

      final entry = QueueEntry(
        id: 1,
        entityType: EntityType.shoppingItem,
        entityId: 'item_123',
        homeId: 'home_123',
        actionType: ActionType.updateItem,
        payload: {'name': 'Apples', 'quantity': 5, 'purchased_quantity': 2},
        createdAt: DateTime.now(),
        idempotencyKey: 'key_123',
      );

      // We expect the update to complete without awaiting since FakePostgrestFilterBuilder
      // doesn't return a Future, but executor won't await it strictly if it's not a real future,
      // actually, dart will just wrap it. Wait, if it awaits a non-future, it completes immediately.
      await executor.execute(entry);

      final capturedUpdates = fakeQueryBuilder.capturedUpdates;
      expect(capturedUpdates, isNotEmpty);
      expect(capturedUpdates.containsKey('purchased_quantity'), isTrue);
      expect(capturedUpdates['purchased_quantity'], 2);
      expect(capturedUpdates['name'], 'Apples');
      expect(capturedUpdates['quantity'], 5);
    });

    test('updateItem action maps estimated_price payload correctly', () async {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(
        const User(
          id: 'user_123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-31T00:00:00Z',
        ),
      );
      when(() => mockClient.from(any())).thenAnswer((invocation) {
        final table = invocation.positionalArguments[0] as String;
        if (table == 'sync_operations_log') {
          throw Exception(
            'Simulated missing log table to skip idempotency checks',
          );
        }
        return fakeQueryBuilder;
      });

      final executor = QueueActionExecutor(mockClient);

      final entry = QueueEntry(
        id: 1,
        entityType: EntityType.shoppingItem,
        entityId: 'item_123',
        homeId: 'home_123',
        actionType: ActionType.updateItem,
        payload: {'estimated_price': 12.5},
        createdAt: DateTime.now(),
        idempotencyKey: 'key_price',
      );

      await executor.execute(entry);

      final capturedUpdates = fakeQueryBuilder.capturedUpdates;
      expect(capturedUpdates['estimated_price'], 12.5);
      expect(capturedUpdates.containsKey('price'), isFalse);
    });

    test(
      'shopping list updateItem action maps rename payload correctly',
      () async {
        final mockClient = MockSupabaseClient();
        final mockAuth = MockGoTrueClient();
        final fakeQueryBuilder = FakeSupabaseQueryBuilder();

        when(() => mockClient.auth).thenReturn(mockAuth);
        when(() => mockAuth.currentUser).thenReturn(
          const User(
            id: 'user_123',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-05-31T00:00:00Z',
          ),
        );
        when(() => mockClient.from(any())).thenAnswer((invocation) {
          final table = invocation.positionalArguments[0] as String;
          if (table == 'sync_operations_log') {
            throw Exception(
              'Simulated missing log table to skip idempotency checks',
            );
          }
          return fakeQueryBuilder;
        });

        final executor = QueueActionExecutor(mockClient);

        final entry = QueueEntry(
          id: 1,
          entityType: EntityType.shoppingList,
          entityId: 'list_123',
          homeId: 'home_123',
          actionType: ActionType.updateItem,
          payload: {'title': 'Weekend groceries'},
          createdAt: DateTime.now(),
          idempotencyKey: 'key_456',
        );

        await executor.execute(entry);

        final capturedUpdates = fakeQueryBuilder.capturedUpdates;
        expect(capturedUpdates['title'], 'Weekend groceries');
        expect(capturedUpdates.containsKey('updated_at'), isTrue);
        expect(capturedUpdates['updated_by'], 'user_123');
      },
    );

    test('createCategory action maps local-first category payload', () async {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(
        const User(
          id: 'user_123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-31T00:00:00Z',
        ),
      );
      when(() => mockClient.from(any())).thenAnswer((invocation) {
        final table = invocation.positionalArguments[0] as String;
        if (table == 'sync_operations_log') {
          throw Exception(
            'Simulated missing log table to skip idempotency checks',
          );
        }
        return fakeQueryBuilder;
      });

      final executor = QueueActionExecutor(mockClient);

      final entry = QueueEntry(
        id: 1,
        entityType: EntityType.category,
        entityId: 'category_123',
        homeId: 'home_123',
        actionType: ActionType.createCategory,
        payload: {
          'home_id': 'home_123',
          'name': 'Produce',
          'type': 'shopping',
          'icon': 'eco',
          'color': '#43A047',
          'sort_order': 3,
        },
        createdAt: DateTime.now(),
        idempotencyKey: 'key_category',
      );

      final result = await executor.execute(entry);

      final capturedUpserts = fakeQueryBuilder.capturedUpserts;
      expect(result, 'category_123');
      expect(capturedUpserts['id'], 'category_123');
      expect(capturedUpserts['home_id'], 'home_123');
      expect(capturedUpserts['name'], 'Produce');
      expect(capturedUpserts['type'], 'shopping');
      expect(capturedUpserts['is_default'], isFalse);
      expect(capturedUpserts['created_by'], 'user_123');
      expect(capturedUpserts.containsKey('updated_at'), isTrue);
    });

    test('startShoppingModeSession action maps session payload', () async {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(
        const User(
          id: 'user_123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-31T00:00:00Z',
        ),
      );
      when(() => mockClient.from(any())).thenAnswer((invocation) {
        final table = invocation.positionalArguments[0] as String;
        if (table == 'sync_operations_log') {
          throw Exception(
            'Simulated missing log table to skip idempotency checks',
          );
        }
        return fakeQueryBuilder;
      });

      final executor = QueueActionExecutor(mockClient);

      final entry = QueueEntry(
        id: 1,
        entityType: EntityType.shoppingModeSession,
        entityId: 'session_123',
        homeId: 'home_123',
        actionType: ActionType.startShoppingModeSession,
        payload: {
          'shopping_list_id': 'list_123',
          'user_id': 'user_123',
          'home_id': 'home_123',
          'started_at': '2026-06-03T08:00:00.000Z',
          'items_total_count': 12,
          'items_purchased_count': 0,
        },
        createdAt: DateTime.now(),
        idempotencyKey: 'key_session',
      );

      final result = await executor.execute(entry);

      final capturedUpserts = fakeQueryBuilder.capturedUpserts;
      expect(result, 'session_123');
      expect(capturedUpserts['id'], 'session_123');
      expect(capturedUpserts['shopping_list_id'], 'list_123');
      expect(capturedUpserts['user_id'], 'user_123');
      expect(capturedUpserts['home_id'], 'home_123');
      expect(capturedUpserts['items_total_count'], 12);
      expect(capturedUpserts['items_purchased_count'], 0);
    });
  });
}
