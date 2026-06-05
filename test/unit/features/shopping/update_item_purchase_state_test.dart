import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/update_item_purchase_state_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  group('UpdateItemPurchaseStateUseCase', () {
    test('updates purchased quantity through repository', () async {
      final repository = MockShoppingListRepository();
      final useCase = UpdateItemPurchaseStateUseCase(repository);
      const item = ShoppingItemModel(
        id: 'item-1',
        shoppingListId: 'list-1',
        name: 'Rice',
        quantity: 4,
        purchasedQuantity: 2,
        createdBy: 'user-1',
      );

      when(
        () => repository.updateItemPurchaseState(
          itemId: any(named: 'itemId'),
          purchasedQuantity: any(named: 'purchasedQuantity'),
        ),
      ).thenAnswer((_) async => item);

      final result = await useCase(itemId: 'item-1', purchasedQuantity: 2);

      expect(result, item);
      verify(
        () => repository.updateItemPurchaseState(
          itemId: 'item-1',
          purchasedQuantity: 2,
        ),
      ).called(1);
    });

    test('rejects negative purchased quantity', () {
      final repository = MockShoppingListRepository();
      final useCase = UpdateItemPurchaseStateUseCase(repository);

      expect(
        () => useCase(itemId: 'item-1', purchasedQuantity: -1),
        throwsArgumentError,
      );
      verifyNever(
        () => repository.updateItemPurchaseState(
          itemId: any(named: 'itemId'),
          purchasedQuantity: any(named: 'purchasedQuantity'),
        ),
      );
    });
  });
}
