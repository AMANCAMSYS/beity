import '../../domain/entities/activity_log.dart';

class ActivityLogModel extends ActivityLog {
  const ActivityLogModel({
    required super.id,
    required super.homeId,
    required super.userId,
    super.actorName,
    required super.action,
    required super.entityType,
    super.entityId,
    super.entityName,
    super.metadata,
    required super.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    final metadataMap = json['metadata'] != null
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : null;

    // Fallback for entity name from metadata if null in database
    String? entityNameFallback = json['entity_name'] as String?;
    if (entityNameFallback == null && metadataMap != null) {
      if (metadataMap.containsKey('name')) {
        entityNameFallback = metadataMap['name'] as String?;
      } else if (metadataMap.containsKey('title')) {
        entityNameFallback = metadataMap['title'] as String?;
      } else if (metadataMap.containsKey('new_title')) {
        entityNameFallback = metadataMap['new_title'] as String?;
      } else if (metadataMap.containsKey('member_name')) {
        entityNameFallback = metadataMap['member_name'] as String?;
      }
    }

    return ActivityLogModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      userId: json['user_id'] as String,
      actorName: json['actor_name'] as String? ?? userData?['full_name'] as String?,
      action: ActionType.fromString(json['action'] as String),
      entityType: EntityType.fromString(json['entity_type'] as String),
      entityId: json['entity_id'] as String?,
      entityName: entityNameFallback,
      metadata: metadataMap,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'user_id': userId,
      'actor_name': actorName,
      'action': action.value,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'entity_name': entityName,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ActivityLogModel copyWithModel({
    String? id,
    String? homeId,
    String? userId,
    String? actorName,
    ActionType? action,
    EntityType? entityType,
    String? entityId,
    String? entityName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
