import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/inventory/data/models/inventory_item_model.dart';
import 'package:sawa/features/inventory/data/models/inventory_transaction_model.dart';
import 'package:sawa/features/inventory/data/repositories/inventory_repository.dart';
import 'package:sawa/features/inventory/domain/usecases/update_inventory_quantity_usecase.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late UpdateInventoryQuantityUseCase useCase;

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = UpdateInventoryQuantityUseCase(mockRepository);
  });

  group('UpdateInventoryQuantityUseCase', () {
    const tItemId = 'inv-123';
    const tHomeId = 'home-123';

    const tItem = InventoryItemModel(
      id: tItemId,
      homeId: tHomeId,
      name: 'Sugar',
      quantity: 5.0,
      createdBy: 'user-123',
      updatedBy: 'user-123',
    );

    const tUpdatedItem = InventoryItemModel(
      id: tItemId,
      homeId: tHomeId,
      name: 'Sugar',
      quantity: 3.0,
      createdBy: 'user-123',
      updatedBy: 'user-123',
    );

    const tOutOfStockItem = InventoryItemModel(
      id: tItemId,
      homeId: tHomeId,
      name: 'Sugar',
      quantity: 0.0,
      createdBy: 'user-123',
      updatedBy: 'user-123',
    );

    final tTransaction = InventoryTransactionModel(
      id: 'txn-123',
      inventoryItemId: tItemId,
      homeId: tHomeId,
      previousQuantity: 5.0,
      newQuantity: 3.0,
      changeReason: 'manual_update',
      changedBy: 'user-123',
      createdAt: DateTime.now(),
    );

    test('should return null and delete item when quantity is <= 0', () async {
      when(
        () => mockRepository.getInventoryItemById(itemId: any(named: 'itemId')),
      ).thenAnswer((_) async => tItem);
      when(
        () => mockRepository.updateInventoryItem(
          itemId: any(named: 'itemId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async => tOutOfStockItem);
      when(
        () => mockRepository.deleteInventoryItem(itemId: any(named: 'itemId')),
      ).thenAnswer((_) async => {});
      when(
        () => mockRepository.createTransaction(
          inventoryItemId: any(named: 'inventoryItemId'),
          homeId: any(named: 'homeId'),
          previousQuantity: any(named: 'previousQuantity'),
          newQuantity: any(named: 'newQuantity'),
          changeReason: any(named: 'changeReason'),
        ),
      ).thenAnswer((_) async => tTransaction);

      final result = await useCase(
        itemId: tItemId,
        homeId: tHomeId,
        newQuantity: 0,
      );

      expect(result, isNull);
      verify(
        () => mockRepository.getInventoryItemById(itemId: tItemId),
      ).called(1);
      verify(
        () => mockRepository.updateInventoryItem(itemId: tItemId, quantity: 0),
      ).called(1);
      verify(
        () => mockRepository.deleteInventoryItem(itemId: tItemId),
      ).called(1);
      verify(
        () => mockRepository.createTransaction(
          inventoryItemId: tItemId,
          homeId: tHomeId,
          previousQuantity: 5.0,
          newQuantity: 0.0,
          changeReason: 'zero_removal',
        ),
      ).called(1);
    });

    test(
      'should update item quantity and write transaction when quantity is > 0',
      () async {
        when(
          () =>
              mockRepository.getInventoryItemById(itemId: any(named: 'itemId')),
        ).thenAnswer((_) async => tItem);
        when(
          () => mockRepository.updateInventoryItem(
            itemId: any(named: 'itemId'),
            quantity: any(named: 'quantity'),
          ),
        ).thenAnswer((_) async => tUpdatedItem);
        when(
          () => mockRepository.createTransaction(
            inventoryItemId: any(named: 'inventoryItemId'),
            homeId: any(named: 'homeId'),
            previousQuantity: any(named: 'previousQuantity'),
            newQuantity: any(named: 'newQuantity'),
            changeReason: any(named: 'changeReason'),
          ),
        ).thenAnswer((_) async => tTransaction);

        final result = await useCase(
          itemId: tItemId,
          homeId: tHomeId,
          newQuantity: 3.0,
        );

        expect(result, tUpdatedItem);
        verify(
          () => mockRepository.getInventoryItemById(itemId: tItemId),
        ).called(1);
        verify(
          () => mockRepository.updateInventoryItem(
            itemId: tItemId,
            quantity: 3.0,
          ),
        ).called(1);
        verify(
          () => mockRepository.createTransaction(
            inventoryItemId: tItemId,
            homeId: tHomeId,
            previousQuantity: 5.0,
            newQuantity: 3.0,
            changeReason: 'manual_update',
          ),
        ).called(1);
      },
    );
  });
}
