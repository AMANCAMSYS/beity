import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/features/shopping_lists/data/repositories/supabase_shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final T value;
  FakePostgrestTransformBuilder(this.value);

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return this;
  }

  @override
  PostgrestTransformBuilder<T> range(
    int from,
    int to, {
    String? referencedTable,
  }) {
    return this;
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(onValue(value));
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late SupabaseShoppingListRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    repository = SupabaseShoppingListRepository(mockClient);

    registerFallbackValue(
      Uri.parse('https://example.com'),
    ); // registered in case it's needed

    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(
      () => mockQueryBuilder.select(any()),
    ).thenAnswer((_) => mockFilterBuilder);
    when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterBuilder);
  });

  group('SupabaseShoppingListRepository', () {
    test(
      'getShoppingLists should build query and return list of models',
      () async {
        final List<Map<String, dynamic>> tResponse = [
          {
            'id': 'list-123',
            'home_id': 'home-123',
            'title': 'Weekly Grocery',
            'type': 'grocery',
            'icon': 'shopping_cart',
            'status': 'active',
            'created_by': 'user-123',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(
          () => mockFilterBuilder.eq('home_id', 'home-123'),
        ).thenAnswer((_) => mockFilterBuilder);
        when(
          () => mockFilterBuilder.filter('deleted_at', 'is', null),
        ).thenAnswer((_) => mockFilterBuilder);

        final fakeTransform =
            FakePostgrestTransformBuilder<List<Map<String, dynamic>>>(
              tResponse,
            );
        when(
          () => mockFilterBuilder.order('created_at', ascending: false),
        ).thenAnswer((_) => fakeTransform);

        final result = await repository.getShoppingLists(homeId: 'home-123');

        expect(result, isNotEmpty);
        expect(result.first.id, 'list-123');
        expect(result.first.name, 'Weekly Grocery');
        expect(result.first.status, ShoppingListStatus.active);

        verify(() => mockClient.from('shopping_lists')).called(1);
        verify(() => mockQueryBuilder.select()).called(1);
      },
    );

    test('getShoppingListById should return model when found', () async {
      final Map<String, dynamic> tResponse = {
        'id': 'list-123',
        'home_id': 'home-123',
        'title': 'Weekly Grocery',
        'type': 'grocery',
        'icon': 'shopping_cart',
        'status': 'active',
        'created_by': 'user-123',
        'created_at': DateTime.now().toIso8601String(),
      };

      when(
        () => mockFilterBuilder.eq('id', 'list-123'),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        () => mockFilterBuilder.filter('deleted_at', 'is', null),
      ).thenAnswer((_) => mockFilterBuilder);

      final fakeTransform =
          FakePostgrestTransformBuilder<Map<String, dynamic>?>(tResponse);
      when(
        () => mockFilterBuilder.maybeSingle(),
      ).thenAnswer((_) => fakeTransform);

      final result = await repository.getShoppingListById(listId: 'list-123');

      expect(result, isNotNull);
      expect(result!.id, 'list-123');
      expect(result.name, 'Weekly Grocery');

      verify(() => mockClient.from('shopping_lists')).called(1);
    });
  });
}
