import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:beity/features/shopping_lists/domain/usecases/delete_list_usecase.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late DeleteListUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = DeleteListUseCase(mockRepository);
  });

  group('DeleteListUseCase', () {
    const tListId = 'list-123';

    test('should delete shopping list in repository', () async {
      when(() => mockRepository.deleteShoppingList(listId: any(named: 'listId')))
          .thenAnswer((_) async => {});

      await useCase(listId: tListId);

      verify(() => mockRepository.deleteShoppingList(listId: tListId)).called(1);
    });
  });
}
