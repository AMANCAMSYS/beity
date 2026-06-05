import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/repositories/shopping_list_repository.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/add_item_usecase.dart';

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepository;
  late AddItemUseCase useCase;

  setUp(() {
    mockRepository = MockShoppingListRepository();
    useCase = AddItemUseCase(mockRepository);
  });

  group('AddItemUseCase', () {
    const tListId = 'list-123';
    const tHomeId = 'home-123';
    const tItemName = 'Milk';
    const tQuantity = 2.0;

    const tItem = ShoppingItemModel(
      id: 'item-123',
      shoppingListId: tListId,
      name: tItemName,
      quantity: tQuantity,
      createdBy: 'user-123',
    );

    test('should throw Exception when item name is empty', () async {
      expect(
        () => useCase(listId: tListId, homeId: tHomeId, name: ''),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw Exception when quantity is <= 0', () async {
      expect(
        () => useCase(
          listId: tListId,
          homeId: tHomeId,
          name: tItemName,
          quantity: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'should throw DuplicateItemException when duplicate exists and skipDuplicateCheck is false',
      () async {
        when(
          () => mockRepository.getShoppingItems(listId: any(named: 'listId')),
        ).thenAnswer((_) async => [tItem]);

        expect(
          () => useCase(listId: tListId, homeId: tHomeId, name: tItemName),
          throwsA(isA<DuplicateItemException>()),
        );
      },
    );

    test(
      'should create item and sync template successfully when valid',
      () async {
        when(
          () => mockRepository.getShoppingItems(listId: any(named: 'listId')),
        ).thenAnswer((_) async => []);

        when(
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
        ).thenAnswer((_) async => tItem);

        when(
          () => mockRepository.syncTemplateOnAdd(
            homeId: any(named: 'homeId'),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            unitId: any(named: 'unitId'),
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => {});

        final result = await useCase(
          listId: tListId,
          homeId: tHomeId,
          name: tItemName,
          quantity: tQuantity,
        );

        expect(result, tItem);
        verify(
          () => mockRepository.createShoppingItem(
            listId: tListId,
            name: tItemName,
            quantity: tQuantity,
          ),
        ).called(1);
        verify(
          () => mockRepository.syncTemplateOnAdd(
            homeId: tHomeId,
            name: tItemName,
            quantity: tQuantity,
          ),
        ).called(1);
      },
    );

    test(
      'should return created item when template sync fails after add',
      () async {
        when(
          () => mockRepository.getShoppingItems(listId: any(named: 'listId')),
        ).thenAnswer((_) async => []);

        when(
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
        ).thenAnswer((_) async => tItem);

        when(
          () => mockRepository.syncTemplateOnAdd(
            homeId: any(named: 'homeId'),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            unitId: any(named: 'unitId'),
            categoryId: any(named: 'categoryId'),
          ),
        ).thenThrow(Exception('offline template sync failed'));

        final result = await useCase(
          listId: tListId,
          homeId: tHomeId,
          name: tItemName,
          quantity: tQuantity,
        );

        expect(result, tItem);
        verify(
          () => mockRepository.createShoppingItem(
            listId: tListId,
            name: tItemName,
            quantity: tQuantity,
          ),
        ).called(1);
        verify(
          () => mockRepository.syncTemplateOnAdd(
            homeId: tHomeId,
            name: tItemName,
            quantity: tQuantity,
          ),
        ).called(1);
      },
    );
  });
}
