import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/notifications/data/models/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('should create model from valid JSON', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'home_id': 'home-1',
        'category': 'system',
        'type': 'item_added',
        'title': 'Test Title',
        'body': 'Test body description',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-1');
      expect(model.userId, 'user-1');
      expect(model.homeId, 'home-1');
      expect(model.category, 'system');
      expect(model.type, 'item_added');
      expect(model.title, 'Test Title');
      expect(model.body, 'Test body description');
      expect(model.isRead, false);
      expect(model.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'home_id': 'home-1',
        'category': 'system',
        'type': 'item_added',
        'title': 'Test Title',
        'body': 'Test body',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000Z',
        'actor_id': null,
        'target_route': null,
        'reference_id': null,
        'reference_type': null,
        'batch_key': null,
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-1');
      expect(model.actorId, isNull);
      expect(model.targetRoute, isNull);
      expect(model.referenceId, isNull);
      expect(model.referenceType, isNull);
      expect(model.batchKey, isNull);
    });
  });

  group('NotificationModel.toJson', () {
    test('should return valid JSON Map', () {
      final model = NotificationModel(
        id: 'notif-1',
        userId: 'user-1',
        homeId: 'home-1',
        category: 'system',
        type: 'item_added',
        title: 'Test Title',
        body: 'Test body',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final json = model.toJson();

      expect(json['id'], 'notif-1');
      expect(json['user_id'], 'user-1');
      expect(json['home_id'], 'home-1');
      expect(json['category'], 'system');
      expect(json['type'], 'item_added');
      expect(json['title'], 'Test Title');
      expect(json['body'], 'Test body');
      expect(json['created_at'], '2026-01-01T00:00:00.000Z');
    });
  });

  group('NotificationModel Entity Mappings', () {
    test('toEntity and fromEntity should preserve all fields', () {
      final model = NotificationModel(
        id: 'notif-1',
        userId: 'user-1',
        homeId: 'home-1',
        category: 'system',
        type: 'item_added',
        title: 'Test Title',
        body: 'Test body',
        actorId: 'actor-1',
        targetRoute: '/home',
        referenceId: 'ref-1',
        referenceType: 'list',
        isRead: true,
        batchKey: 'batch-1',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final entity = model.toEntity();
      expect(entity.id, model.id);
      expect(entity.userId, model.userId);
      expect(entity.homeId, model.homeId);
      expect(entity.category, model.category);
      expect(entity.type, model.type);
      expect(entity.title, model.title);
      expect(entity.body, model.body);
      expect(entity.actorId, model.actorId);
      expect(entity.targetRoute, model.targetRoute);
      expect(entity.referenceId, model.referenceId);
      expect(entity.referenceType, model.referenceType);
      expect(entity.isRead, model.isRead);
      expect(entity.batchKey, model.batchKey);
      expect(entity.createdAt, model.createdAt);

      final mappedBack = NotificationModel.fromEntity(entity);
      expect(mappedBack.id, model.id);
      expect(mappedBack.userId, model.userId);
      expect(mappedBack.homeId, model.homeId);
      expect(mappedBack.category, model.category);
      expect(mappedBack.type, model.type);
      expect(mappedBack.title, model.title);
      expect(mappedBack.body, model.body);
      expect(mappedBack.actorId, model.actorId);
      expect(mappedBack.targetRoute, model.targetRoute);
      expect(mappedBack.referenceId, model.referenceId);
      expect(mappedBack.referenceType, model.referenceType);
      expect(mappedBack.isRead, model.isRead);
      expect(mappedBack.batchKey, model.batchKey);
      expect(mappedBack.createdAt, model.createdAt);
    });
  });
}
