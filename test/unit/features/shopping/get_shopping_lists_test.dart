import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/get_shopping_lists_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late GetShoppingListsUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = GetShoppingListsUseCase(mockRepository);
  });

  group('GetShoppingListsUseCase', () {
    const tHomeId = 'home-123';
    const tStatus = 'active';

    final tShoppingLists = [
      const ShoppingListModel(
        id: 'list-123',
        homeId: tHomeId,
        name: 'List 1',
        createdBy: 'user-123',
        status: ShoppingListStatus.active,
      ),
      const ShoppingListModel(
        id: 'list-456',
        homeId: tHomeId,
        name: 'List 2',
        createdBy: 'user-123',
        status: ShoppingListStatus.active,
      ),
    ];

    test('should return list of shopping lists from repository', () async {
      when(
        () => mockRepository.getShoppingLists(
          homeId: any(named: 'homeId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => tShoppingLists);

      final result = await useCase(homeId: tHomeId, status: tStatus);

      expect(result, tShoppingLists);
      verify(
        () => mockRepository.getShoppingLists(homeId: tHomeId, status: tStatus),
      ).called(1);
    });
  });
}
