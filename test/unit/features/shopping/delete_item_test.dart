import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/delete_item_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late DeleteItemUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = DeleteItemUseCase(mockRepository);
  });

  group('DeleteItemUseCase', () {
    const tItemId = 'item-123';

    const tItem = ShoppingItemModel(
      id: tItemId,
      shoppingListId: 'list-123',
      name: 'Milk',
      quantity: 2.0,
      createdBy: 'user-123',
    );

    test('should delete shopping item through repository', () async {
      when(
        () => mockRepository.deleteShoppingItem(itemId: any(named: 'itemId')),
      ).thenAnswer((_) async => {});

      await useCase(itemId: tItemId);

      verify(
        () => mockRepository.deleteShoppingItem(itemId: tItemId),
      ).called(1);
    });

    test('should return item details when callAndReturn is used', () async {
      when(
        () => mockRepository.getShoppingItemById(itemId: any(named: 'itemId')),
      ).thenAnswer((_) async => tItem);
      when(
        () => mockRepository.deleteShoppingItem(itemId: any(named: 'itemId')),
      ).thenAnswer((_) async => {});

      final result = await useCase.callAndReturn(itemId: tItemId);

      expect(result, tItem);
      verify(
        () => mockRepository.getShoppingItemById(itemId: tItemId),
      ).called(1);
      verify(
        () => mockRepository.deleteShoppingItem(itemId: tItemId),
      ).called(1);
    });

    test('should restore the original item when restoreItem is used', () async {
      when(
        () => mockRepository.restoreShoppingItem(item: tItem),
      ).thenAnswer((_) async => tItem);

      await useCase.restoreItem(item: tItem);

      verify(() => mockRepository.restoreShoppingItem(item: tItem)).called(1);
      verifyNever(
        () => mockRepository.createShoppingItem(
          listId: any(named: 'listId'),
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
          unitId: any(named: 'unitId'),
          categoryId: any(named: 'categoryId'),
          price: any(named: 'price'),
          currency: any(named: 'currency'),
          notes: any(named: 'notes'),
        ),
      );
    });
  });
}
