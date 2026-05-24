import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/shopping_lists/data/models/shopping_item_model.dart';

void main() {
  group('ShoppingItemModel', () {
    test('fromJson parses soft-deleted item with deletedAt', () {
      final json = {
        'id': 'item-1',
        'list_id': 'list-1',
        'name': 'Milk',
        'quantity': 2.0,
        'unit_id': 'unit-1',
        'category_id': 'cat-1',
        'note': 'Full fat',
        'status': 'pending',
        'completed_by': null,
        'completed_at': null,
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
        'deleted_at': '2026-01-03T00:00:00.000Z',
      };

      final item = ShoppingItemModel.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.shoppingListId, 'list-1');
      expect(item.name, 'Milk');
      expect(item.quantity, 2.0);
      expect(item.unitId, 'unit-1');
      expect(item.categoryId, 'cat-1');
      expect(item.notes, 'Full fat');
      expect(item.isPurchased, false);
      expect(item.createdBy, 'user-1');
      expect(item.deletedAt, isNotNull);
      expect(item.deletedAt!.year, 2026);
      expect(item.deletedAt!.month, 1);
      expect(item.deletedAt!.day, 3);
    });

    test('fromJson parses active item with null deletedAt', () {
      final json = {
        'id': 'item-2',
        'list_id': 'list-1',
        'name': 'Bread',
        'quantity': 1.0,
        'status': 'pending',
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      };

      final item = ShoppingItemModel.fromJson(json);

      expect(item.id, 'item-2');
      expect(item.deletedAt, isNull);
      expect(item.unitId, isNull);
      expect(item.categoryId, isNull);
      expect(item.notes, isNull);
    });

    test('fromJson parses completed item', () {
      final json = {
        'id': 'item-3',
        'list_id': 'list-1',
        'name': 'Eggs',
        'quantity': 12.0,
        'status': 'completed',
        'completed_by': 'user-2',
        'completed_at': '2026-01-05T10:00:00.000Z',
        'created_by': 'user-1',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-05T10:00:00.000Z',
      };

      final item = ShoppingItemModel.fromJson(json);

      expect(item.isPurchased, true);
      expect(item.purchasedBy, 'user-2');
      expect(item.purchasedAt, isNotNull);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'id': 'item-4',
        'list_id': 'list-1',
        'name': 'Butter',
        'created_by': 'user-1',
      };

      final item = ShoppingItemModel.fromJson(json);

      expect(item.id, 'item-4');
      expect(item.quantity, 1.0); // default
      expect(item.unitId, isNull);
      expect(item.categoryId, isNull);
      expect(item.notes, isNull);
      expect(item.isPurchased, false); // default
      expect(item.purchasedBy, isNull);
      expect(item.purchasedAt, isNull);
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
      expect(item.deletedAt, isNull);
      expect(item.currency, 'SAR'); // default
    });

    test('copyWithModel preserves existing values when no changes', () {
      final original = ShoppingItemModel(
        id: 'item-1',
        shoppingListId: 'list-1',
        name: 'Milk',
        quantity: 2.0,
        unitId: 'unit-1',
        categoryId: 'cat-1',
        notes: 'Full fat',
        createdBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final copy = original.copyWithModel();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.quantity, original.quantity);
      expect(copy.unitId, original.unitId);
      expect(copy.categoryId, original.categoryId);
      expect(copy.notes, original.notes);
    });

    test('copyWithModel overrides specified fields', () {
      final original = ShoppingItemModel(
        id: 'item-1',
        shoppingListId: 'list-1',
        name: 'Milk',
        quantity: 2.0,
        createdBy: 'user-1',
      );

      final copy = original.copyWithModel(
        name: 'Almond Milk',
        quantity: 3.0,
      );

      expect(copy.id, original.id); // preserved
      expect(copy.name, 'Almond Milk'); // changed
      expect(copy.quantity, 3.0); // changed
      expect(copy.shoppingListId, original.shoppingListId); // preserved
    });

    test('toJson produces correct database column names', () {
      final item = ShoppingItemModel(
        id: 'item-1',
        shoppingListId: 'list-1',
        name: 'Milk',
        quantity: 2.0,
        unitId: 'unit-1',
        notes: 'test note',
        isPurchased: true,
        purchasedBy: 'user-2',
        createdBy: 'user-1',
      );

      final json = item.toJson();

      expect(json['list_id'], 'list-1'); // not shoppingListId
      expect(json['note'], 'test note'); // not notes
      expect(json['status'], 'completed'); // not isPurchased
      expect(json['completed_by'], 'user-2'); // not purchasedBy
    });
  });
}
