import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/inventory/data/models/inventory_item_model.dart';

void main() {
  group('LowStockAlert & RestockSuggestions', () {
    test('isLowStock returns true when quantity is <= minQuantity', () {
      const item1 = InventoryItemModel(
        id: 'inv-123',
        homeId: 'home-123',
        name: 'Sugar',
        quantity: 1.0,
        minQuantity: 2.0,
        createdBy: 'user-123',
        updatedBy: 'user-123',
      );

      const item2 = InventoryItemModel(
        id: 'inv-123',
        homeId: 'home-123',
        name: 'Sugar',
        quantity: 2.0,
        minQuantity: 2.0,
        createdBy: 'user-123',
        updatedBy: 'user-123',
      );

      expect(item1.isLowStock, isTrue);
      expect(item2.isLowStock, isTrue);
    });

    test(
      'isLowStock returns false when quantity is > minQuantity or minQuantity is null',
      () {
        const item1 = InventoryItemModel(
          id: 'inv-123',
          homeId: 'home-123',
          name: 'Sugar',
          quantity: 3.0,
          minQuantity: 2.0,
          createdBy: 'user-123',
          updatedBy: 'user-123',
        );

        const item2 = InventoryItemModel(
          id: 'inv-123',
          homeId: 'home-123',
          name: 'Sugar',
          quantity: 1.0,
          minQuantity: null,
          createdBy: 'user-123',
          updatedBy: 'user-123',
        );

        expect(item1.isLowStock, isFalse);
        expect(item2.isLowStock, isFalse);
      },
    );

    test('restockSuggestion returns correct quantity calculations', () {
      const item1 = InventoryItemModel(
        id: 'inv-123',
        homeId: 'home-123',
        name: 'Sugar',
        quantity: 1.0,
        minQuantity: 3.0,
        createdBy: 'user-123',
        updatedBy: 'user-123',
      );

      const item2 = InventoryItemModel(
        id: 'inv-123',
        homeId: 'home-123',
        name: 'Sugar',
        quantity: 1.0,
        minQuantity: null,
        createdBy: 'user-123',
        updatedBy: 'user-123',
      );

      expect(item1.restockSuggestion, 5.0); // (3 * 2) - 1 = 5
      expect(item2.restockSuggestion, 0.0); // minQuantity is null
    });
  });
}
