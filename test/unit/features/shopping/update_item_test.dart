import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/update_item_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late UpdateItemUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = UpdateItemUseCase(mockRepository);
  });

  group('UpdateItemUseCase', () {
    const tItemId = 'item-123';
    const tItemName = 'Eggs';
    const tQuantity = 12.0;

    const tItem = ShoppingItemModel(
      id: tItemId,
      shoppingListId: 'list-123',
      name: tItemName,
      quantity: tQuantity,
      createdBy: 'user-123',
    );

    test('should throw Exception when name is empty', () async {
      expect(
        () => useCase(itemId: tItemId, name: ''),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw Exception when quantity is <= 0', () async {
      expect(
        () => useCase(itemId: tItemId, quantity: 0),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'should update item in repository and return the updated item',
      () async {
        when(
          () => mockRepository.updateShoppingItem(
            itemId: any(named: 'itemId'),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            unitId: any(named: 'unitId'),
            categoryId: any(named: 'categoryId'),
            price: any(named: 'price'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => tItem);

        final result = await useCase(
          itemId: tItemId,
          name: tItemName,
          quantity: tQuantity,
        );

        expect(result, tItem);
        verify(
          () => mockRepository.updateShoppingItem(
            itemId: tItemId,
            name: tItemName,
            quantity: tQuantity,
          ),
        ).called(1);
      },
    );
  });
}
