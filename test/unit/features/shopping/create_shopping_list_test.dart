import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/create_shopping_list_usecase.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late CreateShoppingListUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = CreateShoppingListUseCase(mockRepository);
  });

  group('CreateShoppingListUseCase', () {
    const tHomeId = 'home-123';
    const tListName = 'My Shopping List';
    const tDescription = 'Weekly groceries';
    const tIcon = 'shopping_cart';

    const tShoppingList = ShoppingListModel(
      id: 'list-123',
      homeId: tHomeId,
      name: tListName,
      description: tDescription,
      icon: tIcon,
      status: ShoppingListStatus.active,
      createdBy: 'user-123',
    );

    test('should throw Exception when list name is empty', () async {
      expect(
        () => useCase(homeId: tHomeId, name: ''),
        throwsA(isA<Exception>()),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should call repository.createShoppingList and return the created list', () async {
      when(() => mockRepository.createShoppingList(
            homeId: any(named: 'homeId'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            icon: any(named: 'icon'),
          )).thenAnswer((_) async => tShoppingList);

      final result = await useCase(
        homeId: tHomeId,
        name: tListName,
        description: tDescription,
        icon: tIcon,
      );

      expect(result, tShoppingList);
      verify(() => mockRepository.createShoppingList(
            homeId: tHomeId,
            name: tListName,
            description: tDescription,
            icon: tIcon,
          )).called(1);
    });
  });
}
