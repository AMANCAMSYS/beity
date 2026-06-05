import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/complete_list_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late CompleteListUseCase useCase;

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = CompleteListUseCase(repository);
  });

  test('updates shopping list status to completed', () async {
    when(
      () => repository.updateShoppingList(
        listId: any(named: 'listId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const ShoppingListModel(
        id: 'list-1',
        homeId: 'home-1',
        name: 'Groceries',
        createdBy: 'user-1',
        status: ShoppingListStatus.completed,
      ),
    );

    await useCase(listId: 'list-1');

    verify(
      () =>
          repository.updateShoppingList(listId: 'list-1', status: 'completed'),
    ).called(1);
  });
}
