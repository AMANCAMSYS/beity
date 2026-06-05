import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/archive_list_usecase.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late ArchiveListUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = ArchiveListUseCase(mockRepository);
  });

  group('ArchiveListUseCase', () {
    const tListId = 'list-123';

    const tShoppingList = ShoppingListModel(
      id: tListId,
      homeId: 'home-123',
      name: 'List 1',
      createdBy: 'user-123',
      status: ShoppingListStatus.archived,
    );

    const tActiveShoppingList = ShoppingListModel(
      id: tListId,
      homeId: 'home-123',
      name: 'List 1',
      createdBy: 'user-123',
      status: ShoppingListStatus.active,
    );

    test('should update shopping list status to archived in repository', () async {
      when(() => mockRepository.updateShoppingList(
            listId: any(named: 'listId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => tShoppingList);

      await useCase(listId: tListId);

      verify(() => mockRepository.updateShoppingList(
            listId: tListId,
            status: 'archived',
          )).called(1);
    });

    test('should restore (status to active) shopping list through repository', () async {
      when(() => mockRepository.updateShoppingList(
            listId: any(named: 'listId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => tActiveShoppingList);

      await useCase.restore(listId: tListId);

      verify(() => mockRepository.updateShoppingList(
            listId: tListId,
            status: 'active',
          )).called(1);
    });
  });
}
