import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/mark_item_purchased_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late MarkItemPurchasedUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = MarkItemPurchasedUseCase(mockRepository);
  });

  group('MarkItemPurchasedUseCase', () {
    const tItemId = 'item-123';

    const tItem = ShoppingItemModel(
      id: tItemId,
      shoppingListId: 'list-123',
      name: 'Milk',
      quantity: 2.0,
      isPurchased: true,
      createdBy: 'user-123',
    );

    test('should mark shopping item as purchased through repository', () async {
      when(
        () => mockRepository.markItemPurchased(
          itemId: any(named: 'itemId'),
          isPurchased: any(named: 'isPurchased'),
        ),
      ).thenAnswer((_) async => tItem);

      final result = await useCase(itemId: tItemId, isPurchased: true);

      expect(result, tItem);
      verify(
        () => mockRepository.markItemPurchased(
          itemId: tItemId,
          isPurchased: true,
        ),
      ).called(1);
    });
  });
}
