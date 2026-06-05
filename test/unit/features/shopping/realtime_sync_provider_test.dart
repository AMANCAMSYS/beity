import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_items_provider.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  const homeId = 'home-1';
  const listId = 'list-1';

  final baseItem = ShoppingItemModel(
    id: 'item-1',
    shoppingListId: listId,
    name: 'Milk',
    quantity: 2,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 6, 1),
  );

  final purchasedItem = baseItem.copyWithModel(
    isPurchased: true,
    purchasedQuantity: 2,
    purchasedAt: DateTime(2026, 6, 1, 12),
    updatedAt: DateTime(2026, 6, 1, 12),
  );

  final baseList = ShoppingListModel(
    id: listId,
    homeId: homeId,
    name: 'Groceries',
    createdBy: 'user-1',
    status: ShoppingListStatus.active,
    createdAt: DateTime(2026, 6, 1),
  );

  group('Realtime sync via live Drift streams', () {
    test('shoppingItemsProvider updates when stream emits new data '
        '(simulating RealtimeSyncService writing to Drift)', () async {
      final repository = MockShoppingListRepository();
      final itemsController =
          StreamController<List<ShoppingItemModel>>.broadcast();

      when(
        () => repository.watchShoppingItems(listId: listId),
      ).thenAnswer((_) => itemsController.stream);

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          shoppingListRepositoryForHomeProvider(
            homeId,
          ).overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe to trigger provider lifecycle
      final sub = container.listen(
        shoppingItemsProvider(listId),
        (prev, next) {},
      );
      addTearDown(sub.close);

      // Device A adds item → RealtimeSyncService writes to Drift → stream emits
      itemsController.add([baseItem]);
      await container.pump();

      final items1 = container.read(shoppingItemsProvider(listId)).value!;
      expect(items1.length, 1);
      expect(items1.first.name, 'Milk');
      expect(items1.first.isPurchased, false);

      // Device A marks item purchased → RealtimeSyncService writes to Drift
      itemsController.add([purchasedItem]);
      await container.pump();

      final items2 = container.read(shoppingItemsProvider(listId)).value!;
      expect(items2.first.isPurchased, true);
      expect(items2.first.purchasedQuantity, 2);

      await itemsController.close();
    });

    test(
      'shoppingItemsForHomeProvider updates when stream emits new data',
      () async {
        final repository = MockShoppingListRepository();
        final itemsController =
            StreamController<List<ShoppingItemModel>>.broadcast();

        when(
          () => repository.watchShoppingItems(listId: listId),
        ).thenAnswer((_) => itemsController.stream);

        final container = ProviderContainer(
          overrides: [
            shoppingListRepositoryForHomeProvider(
              homeId,
            ).overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        const params = (listId: listId, homeId: homeId);
        final sub = container.listen(
          shoppingItemsForHomeProvider(params),
          (prev, next) {},
        );
        addTearDown(sub.close);

        // Simulate realtime item arrival
        itemsController.add([baseItem]);
        await container.pump();

        final items1 = container
            .read(shoppingItemsForHomeProvider(params))
            .value!;
        expect(items1.length, 1);
        expect(items1.first.isPurchased, false);

        // Simulate purchase state change
        itemsController.add([purchasedItem]);
        await container.pump();

        final items2 = container
            .read(shoppingItemsForHomeProvider(params))
            .value!;
        expect(items2.first.isPurchased, true);

        await itemsController.close();
      },
    );

    test('shoppingListsProvider updates when stream emits new data', () async {
      final repository = MockShoppingListRepository();
      final listsController =
          StreamController<List<ShoppingListModel>>.broadcast();

      when(
        () => repository.watchShoppingLists(
          homeId: homeId,
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) => listsController.stream);

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryForHomeProvider(
            homeId,
          ).overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        shoppingListsProvider(homeId),
        (prev, next) {},
      );
      addTearDown(sub.close);

      // Simulate realtime list arrival
      listsController.add([baseList]);
      await container.pump();

      final lists = container.read(shoppingListsProvider(homeId)).value!;
      expect(lists.length, 1);
      expect(lists.first.name, 'Groceries');

      await listsController.close();
    });

    test(
      'shoppingModeProgressProvider updates when item purchase state changes',
      () async {
        final repository = MockShoppingListRepository();
        final itemsController =
            StreamController<List<ShoppingItemModel>>.broadcast();

        when(
          () => repository.watchShoppingItems(listId: listId),
        ).thenAnswer((_) => itemsController.stream);

        final container = ProviderContainer(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        // Seed with 3 items, none purchased
        final items = [
          baseItem,
          const ShoppingItemModel(
            id: 'item-2',
            shoppingListId: listId,
            name: 'Bread',
            quantity: 1,
            createdBy: 'user-1',
          ),
          const ShoppingItemModel(
            id: 'item-3',
            shoppingListId: listId,
            name: 'Eggs',
            quantity: 12,
            createdBy: 'user-1',
          ),
        ];

        final sub = container.listen(
          shoppingItemsProvider(listId),
          (prev, next) {},
        );
        addTearDown(sub.close);

        itemsController.add(items);
        await container.pump();

        // Verify initial state: 0 purchased, 3 total, 0% progress
        expect(container.read(shoppingModePurchasedCountProvider(listId)), 0);
        expect(container.read(shoppingModeTotalCountProvider(listId)), 3);
        expect(container.read(shoppingModeProgressProvider(listId)), 0.0);

        // Simulate: user purchases Milk → RealtimeSyncService writes to Drift
        itemsController.add([
          items[0].copyWithModel(
            isPurchased: true,
            purchasedQuantity: 2,
            purchasedAt: DateTime(2026, 6, 1, 12),
          ),
          items[1],
          items[2],
        ]);
        await container.pump();

        // Verify: 1 purchased, 3 total, progress updated
        expect(container.read(shoppingModePurchasedCountProvider(listId)), 1);
        expect(container.read(shoppingModeTotalCountProvider(listId)), 3);
        expect(
          container.read(shoppingModeProgressProvider(listId)),
          closeTo(0.333, 0.01),
        );

        await itemsController.close();
      },
    );

    test(
      'multiple Device B listeners see the same update simultaneously',
      () async {
        final repository = MockShoppingListRepository();
        final itemsController =
            StreamController<List<ShoppingItemModel>>.broadcast();

        when(
          () => repository.watchShoppingItems(listId: listId),
        ).thenAnswer((_) => itemsController.stream);

        final container = ProviderContainer(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repository),
            shoppingListRepositoryForHomeProvider(
              homeId,
            ).overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        // Two different screens/widgets watching the same list
        const params = (listId: listId, homeId: homeId);
        final sub1 = container.listen(
          shoppingItemsProvider(listId),
          (prev, next) {},
        );
        final sub2 = container.listen(
          shoppingItemsForHomeProvider(params),
          (prev, next) {},
        );
        addTearDown(sub1.close);
        addTearDown(sub2.close);

        // Device A adds item
        itemsController.add([baseItem]);
        await container.pump();

        // Both listeners see the update without manual invalidation
        final items1 = container.read(shoppingItemsProvider(listId)).value!;
        final items2 = container
            .read(shoppingItemsForHomeProvider(params))
            .value!;
        expect(items1.length, 1);
        expect(items2.length, 1);
        expect(items1.first.name, items2.first.name);

        await itemsController.close();
      },
    );

    test('shoppingListSummariesProvider (via shoppingListsProvider) '
        'reflects item changes through Drift stream', () async {
      final repository = MockShoppingListRepository();
      final listsController =
          StreamController<List<ShoppingListModel>>.broadcast();
      final itemsController =
          StreamController<List<ShoppingItemModel>>.broadcast();

      when(
        () => repository.watchShoppingLists(
          homeId: homeId,
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) => listsController.stream);

      when(
        () => repository.watchShoppingItems(listId: listId),
      ).thenAnswer((_) => itemsController.stream);

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryForHomeProvider(
            homeId,
          ).overrideWithValue(repository),
          shoppingListRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final listsSub = container.listen(
        shoppingListsProvider(homeId),
        (prev, next) {},
      );
      addTearDown(listsSub.close);

      // Initial state: list with 2 items, 0 purchased
      listsController.add([baseList]);
      await container.pump();

      final itemsSub = container.listen(
        shoppingItemsProvider(listId),
        (prev, next) {},
      );
      addTearDown(itemsSub.close);

      itemsController.add([
        baseItem,
        const ShoppingItemModel(
          id: 'item-2',
          shoppingListId: listId,
          name: 'Bread',
          quantity: 1,
          createdBy: 'user-1',
        ),
      ]);
      await container.pump();

      // Verify items are available
      final items1 = container.read(shoppingItemsProvider(listId)).value!;
      expect(items1.length, 2);
      expect(items1.where((i) => i.isPurchased).length, 0);

      // Simulate: user purchases Milk
      itemsController.add([
        baseItem.copyWithModel(
          isPurchased: true,
          purchasedQuantity: 2,
          purchasedAt: DateTime(2026, 6, 1, 12),
        ),
        const ShoppingItemModel(
          id: 'item-2',
          shoppingListId: listId,
          name: 'Bread',
          quantity: 1,
          createdBy: 'user-1',
        ),
      ]);
      await container.pump();

      // Verify: items stream reflects purchase
      final items2 = container.read(shoppingItemsProvider(listId)).value!;
      expect(items2.where((i) => i.isPurchased).length, 1);
      expect(items2.where((i) => !i.isPurchased).length, 1);

      await listsController.close();
      await itemsController.close();
    });
  });
}
