import '../../domain/entities/notification.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String homeId;
  final String category;
  final String type;
  final String title;
  final String body;
  final String? actorId;
  final String? targetRoute;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final String? batchKey;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.homeId,
    required this.category,
    required this.type,
    required this.title,
    required this.body,
    this.actorId,
    this.targetRoute,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    this.batchKey,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      homeId: json['home_id'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      actorId: json['actor_id'] as String?,
      targetRoute: json['target_route'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      batchKey: json['batch_key'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'home_id': homeId,
      'category': category,
      'type': type,
      'title': title,
      'body': body,
      'actor_id': actorId,
      'target_route': targetRoute,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'is_read': isRead,
      'batch_key': batchKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      userId: userId,
      homeId: homeId,
      category: category,
      type: type,
      title: title,
      body: body,
      actorId: actorId,
      targetRoute: targetRoute,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead,
      batchKey: batchKey,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromEntity(AppNotification entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      homeId: entity.homeId,
      category: entity.category,
      type: entity.type,
      title: entity.title,
      body: entity.body,
      actorId: entity.actorId,
      targetRoute: entity.targetRoute,
      referenceId: entity.referenceId,
      referenceType: entity.referenceType,
      isRead: entity.isRead,
      batchKey: entity.batchKey,
      createdAt: entity.createdAt,
    );
  }
}
