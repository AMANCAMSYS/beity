import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_items_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart';

ShoppingItemModel item({
  required String id,
  required double quantity,
  double purchasedQuantity = 0,
  bool isPurchased = false,
}) {
  return ShoppingItemModel(
    id: id,
    shoppingListId: 'list-1',
    name: id,
    quantity: quantity,
    purchasedQuantity: purchasedQuantity,
    isPurchased: isPurchased,
    createdBy: 'user-1',
  );
}

void main() {
  test('progress includes full and partial purchases', () async {
    final items = [
      item(id: 'milk', quantity: 1, isPurchased: true),
      item(id: 'rice', quantity: 4, purchasedQuantity: 2),
      item(id: 'eggs', quantity: 12),
    ];
    final container = ProviderContainer(
      overrides: [
        shoppingItemsProvider(
          'list-1',
        ).overrideWith((ref) => Stream.value(items)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      shoppingItemsProvider('list-1'),
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await container.read(shoppingItemsProvider('list-1').future);

    expect(container.read(shoppingModePurchasedCountProvider('list-1')), 1);
    expect(container.read(shoppingModeTotalCountProvider('list-1')), 3);
    expect(container.read(shoppingModeProgressProvider('list-1')), 0.5);
  });

  test('home-scoped progress uses the home-specific item stream', () async {
    const params = (listId: 'list-1', homeId: 'home-1');
    final items = [
      item(id: 'apples', quantity: 2, purchasedQuantity: 1),
      item(id: 'bread', quantity: 1, isPurchased: true),
    ];
    final container = ProviderContainer(
      overrides: [
        shoppingItemsForHomeProvider(
          params,
        ).overrideWith((ref) => Stream.value(items)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      shoppingItemsForHomeProvider(params),
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await container.read(shoppingItemsForHomeProvider(params).future);

    expect(
      container.read(shoppingModePurchasedCountForHomeProvider(params)),
      1,
    );
    expect(container.read(shoppingModeTotalCountForHomeProvider(params)), 2);
    expect(container.read(shoppingModeProgressForHomeProvider(params)), 0.75);
  });
}
