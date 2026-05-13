import '../../domain/entities/notification_preference.dart';

class NotificationPreferenceModel {
  final String id;
  final String userId;
  final String category;
  final bool enabled;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferenceModel({
    required this.id,
    required this.userId,
    required this.category,
    this.enabled = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'enabled': enabled,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationPreference toEntity() {
    return NotificationPreference(
      id: id,
      userId: userId,
      category: category,
      enabled: enabled,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory NotificationPreferenceModel.fromEntity(NotificationPreference entity) {
    return NotificationPreferenceModel(
      id: entity.id,
      userId: entity.userId,
      category: entity.category,
      enabled: entity.enabled,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
