import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  test('shoppingListsProvider sorts lists by newest createdAt first', () async {
    final repository = MockShoppingListRepository();
    final oldCreatedAt = DateTime(2026, 5, 1);
    final newCreatedAt = DateTime(2026, 6, 1);

    when(
      () => repository.watchShoppingLists(
        homeId: 'home-1',
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) => Stream.value([
        ShoppingListModel(
          id: 'old-list',
          homeId: 'home-1',
          name: 'Old list',
          createdBy: 'user-1',
          createdAt: oldCreatedAt,
        ),
        ShoppingListModel(
          id: 'new-list',
          homeId: 'home-1',
          name: 'New list',
          createdBy: 'user-1',
          createdAt: newCreatedAt,
        ),
      ]),
    );

    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryForHomeProvider(
          'home-1',
        ).overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      shoppingListsProvider('home-1'),
      (previous, next) {},
    );
    addTearDown(subscription.close);

    final result = await container.read(shoppingListsProvider('home-1').future);

    expect(result.map((list) => list.id), ['new-list', 'old-list']);
  });

  test(
    'shoppingListsProvider refreshes when local list stream emits',
    () async {
      final repository = MockShoppingListRepository();
      final streamController =
          StreamController<List<ShoppingListModel>>.broadcast();
      addTearDown(streamController.close);

      when(
        () => repository.watchShoppingLists(
          homeId: 'home-1',
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) => streamController.stream);

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryForHomeProvider(
            'home-1',
          ).overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        shoppingListsProvider('home-1'),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      streamController.add([
        const ShoppingListModel(
          id: 'list-1',
          homeId: 'home-1',
          name: 'Old list',
          createdBy: 'user-1',
        ),
      ]);

      final first = await container.read(
        shoppingListsProvider('home-1').future,
      );
      expect(first.single.name, 'Old list');

      streamController.add([
        const ShoppingListModel(
          id: 'list-2',
          homeId: 'home-1',
          name: 'New list',
          createdBy: 'user-1',
        ),
      ]);
      await container.pump();

      final second = container.read(shoppingListsProvider('home-1')).value!;
      expect(second.single.name, 'New list');
      verify(
        () => repository.watchShoppingLists(
          homeId: 'home-1',
          status: any(named: 'status'),
        ),
      ).called(1);
    },
  );
}
