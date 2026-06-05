import 'package:flutter_test/flutter_test.dart';

import 'package:sawa/features/notifications/data/models/notification_preference_model.dart';
import 'package:sawa/features/notifications/domain/entities/notification_preference.dart';

void main() {
  group('NotificationPreferencesModel', () {
    // -----------------------------------------------------------------------
    // fromJson – happy path (all columns present)
    // -----------------------------------------------------------------------
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'user_id': 'user-1',
        'home_id': 'home-1',
        'item_added': false,
        'item_completed': true,
        'low_stock': false,
        'expiry_alert': true,
        'expense_added': false,
        'task_due': true,
        'created_at': '2026-05-14T00:00:00.000Z',
        'updated_at': '2026-05-14T01:00:00.000Z',
      };

      final model = NotificationPreferencesModel.fromJson(json);

      expect(model.id, 'abc-123');
      expect(model.userId, 'user-1');
      expect(model.homeId, 'home-1');
      expect(model.itemAdded, isFalse);
      expect(model.itemCompleted, isTrue);
      expect(model.lowStock, isFalse);
      expect(model.expiryAlert, isTrue);
      expect(model.expenseAdded, isFalse);
      expect(model.taskDue, isTrue);
    });

    // -----------------------------------------------------------------------
    // fromJson – null / missing fields fall back to defaults
    // -----------------------------------------------------------------------
    test('fromJson returns defaults for null / missing boolean fields', () {
      final json = <String, dynamic>{
        'id': null,
        'user_id': null,
        'home_id': null,
        'item_added': null,
        'item_completed': null,
        'low_stock': null,
        'expiry_alert': null,
        'expense_added': null,
        'task_due': null,
        'created_at': null,
        'updated_at': null,
      };

      final model = NotificationPreferencesModel.fromJson(json);

      expect(model.id, '');
      expect(model.userId, '');
      expect(model.homeId, '');
      expect(model.itemAdded, isTrue);
      expect(model.itemCompleted, isTrue);
      expect(model.lowStock, isTrue);
      expect(model.expiryAlert, isTrue);
      expect(model.expenseAdded, isTrue);
      expect(model.taskDue, isTrue);
      // Dates fall back to DateTime.now() — just verify they are non-null
      expect(model.createdAt, isA<DateTime>());
      expect(model.updatedAt, isA<DateTime>());
    });

    test('fromJson does not throw on completely empty map', () {
      final model = NotificationPreferencesModel.fromJson({});

      expect(model.id, '');
      expect(model.itemAdded, isTrue);
    });

    // -----------------------------------------------------------------------
    // toEntity – round-trip
    // -----------------------------------------------------------------------
    test('toEntity converts correctly', () {
      final model = NotificationPreferencesModel(
        id: 'id-1',
        userId: 'user-1',
        homeId: 'home-1',
        itemAdded: false,
        itemCompleted: false,
        lowStock: false,
        expiryAlert: false,
        expenseAdded: false,
        taskDue: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final entity = model.toEntity();

      expect(entity, isA<NotificationPreferences>());
      expect(entity.itemAdded, isFalse);
      expect(entity.taskDue, isFalse);
      expect(entity.homeId, 'home-1');
    });

    // -----------------------------------------------------------------------
    // copyWith on entity
    // -----------------------------------------------------------------------
    test('NotificationPreferences.copyWith updates only specified fields', () {
      final original = NotificationPreferences(
        id: 'id-1',
        userId: 'user-1',
        homeId: 'home-1',
        itemAdded: true,
        itemCompleted: true,
        lowStock: true,
        expiryAlert: true,
        expenseAdded: true,
        taskDue: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(itemAdded: false, taskDue: false);

      expect(updated.itemAdded, isFalse);
      expect(updated.taskDue, isFalse);
      // Other fields unchanged
      expect(updated.itemCompleted, isTrue);
      expect(updated.lowStock, isTrue);
      expect(updated.homeId, 'home-1');
    });

    // -----------------------------------------------------------------------
    // toJson
    // -----------------------------------------------------------------------
    test('toJson produces correct map for upsert', () {
      final model = NotificationPreferencesModel(
        id: 'id-1',
        userId: 'user-1',
        homeId: 'home-1',
        itemAdded: true,
        itemCompleted: false,
        lowStock: true,
        expiryAlert: false,
        expenseAdded: true,
        taskDue: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = model.toJson();

      expect(json['user_id'], 'user-1');
      expect(json['home_id'], 'home-1');
      expect(json['item_added'], isTrue);
      expect(json['item_completed'], isFalse);
      expect(json['task_due'], isFalse);
      // id, created_at, updated_at should NOT be in the upsert payload
      expect(json.containsKey('id'), isFalse);
    });
  });
}
