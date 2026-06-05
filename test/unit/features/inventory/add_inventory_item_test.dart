import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/inventory/data/models/inventory_item_model.dart';
import 'package:sawa/features/inventory/data/models/inventory_transaction_model.dart';
import 'package:sawa/features/inventory/data/repositories/inventory_repository.dart';
import 'package:sawa/features/inventory/domain/usecases/add_inventory_item_usecase.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late AddInventoryItemUseCase useCase;

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = AddInventoryItemUseCase(mockRepository);
  });

  group('AddInventoryItemUseCase', () {
    const tHomeId = 'home-123';
    const tName = 'Sugar';
    const tQuantity = 2.0;

    const tExistingItem = InventoryItemModel(
      id: 'inv-123',
      homeId: tHomeId,
      name: tName,
      quantity: 1.0,
      createdBy: 'user-123',
      updatedBy: 'user-123',
    );

    const tUpdatedItem = InventoryItemModel(
      id: 'inv-123',
      homeId: tHomeId,
      name: tName,
      quantity: 3.0,
      createdBy: 'user-123',
      updatedBy: 'user-123',
    );

    const tNewItem = InventoryItemModel(
      id: 'inv-456',
      homeId: tHomeId,
      name: tName,
      quantity: tQuantity,
      createdBy: 'user-123',
      updatedBy: 'user-123',
    );

    final tTransaction = InventoryTransactionModel(
      id: 'txn-123',
      inventoryItemId: 'inv-123',
      homeId: tHomeId,
      previousQuantity: 1.0,
      newQuantity: 3.0,
      changeReason: 'manual_update',
      changedBy: 'user-123',
      createdAt: DateTime.now(),
    );

    test('should update quantity and create transaction when duplicate is found', () async {
      when(() => mockRepository.findDuplicateItem(
            homeId: any(named: 'homeId'),
            name: any(named: 'name'),
            unitId: any(named: 'unitId'),
          )).thenAnswer((_) async => tExistingItem);

      when(() => mockRepository.updateInventoryItem(
            itemId: any(named: 'itemId'),
            quantity: any(named: 'quantity'),
          )).thenAnswer((_) async => tUpdatedItem);

      when(() => mockRepository.createTransaction(
            inventoryItemId: any(named: 'inventoryItemId'),
            homeId: any(named: 'homeId'),
            previousQuantity: any(named: 'previousQuantity'),
            newQuantity: any(named: 'newQuantity'),
            changeReason: any(named: 'changeReason'),
          )).thenAnswer((_) async => tTransaction);

      final result = await useCase(
        homeId: tHomeId,
        name: tName,
        quantity: tQuantity,
      );

      expect(result.quantity, 3.0);
      verify(() => mockRepository.findDuplicateItem(homeId: tHomeId, name: tName)).called(1);
      verify(() => mockRepository.updateInventoryItem(itemId: tExistingItem.id, quantity: 3.0)).called(1);
      verify(() => mockRepository.createTransaction(
            inventoryItemId: tExistingItem.id,
            homeId: tHomeId,
            previousQuantity: 1.0,
            newQuantity: 3.0,
            changeReason: 'manual_update',
          )).called(1);
    });

    test('should create new item and transaction when duplicate is not found', () async {
      when(() => mockRepository.findDuplicateItem(
            homeId: any(named: 'homeId'),
            name: any(named: 'name'),
            unitId: any(named: 'unitId'),
          )).thenAnswer((_) async => null);

      when(() => mockRepository.createInventoryItem(
            homeId: any(named: 'homeId'),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            unitId: any(named: 'unitId'),
            categoryId: any(named: 'categoryId'),
            minQuantity: any(named: 'minQuantity'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => tNewItem);

      when(() => mockRepository.createTransaction(
            inventoryItemId: any(named: 'inventoryItemId'),
            homeId: any(named: 'homeId'),
            previousQuantity: any(named: 'previousQuantity'),
            newQuantity: any(named: 'newQuantity'),
            changeReason: any(named: 'changeReason'),
          )).thenAnswer((_) async => tTransaction);

      final result = await useCase(
        homeId: tHomeId,
        name: tName,
        quantity: tQuantity,
      );

      expect(result, tNewItem);
      verify(() => mockRepository.findDuplicateItem(homeId: tHomeId, name: tName)).called(1);
      verify(() => mockRepository.createInventoryItem(
            homeId: tHomeId,
            name: tName,
            quantity: tQuantity,
          )).called(1);
      verify(() => mockRepository.createTransaction(
            inventoryItemId: tNewItem.id,
            homeId: tHomeId,
            previousQuantity: 0,
            newQuantity: tQuantity,
            changeReason: 'initial_add',
          )).called(1);
    });
  });
}
