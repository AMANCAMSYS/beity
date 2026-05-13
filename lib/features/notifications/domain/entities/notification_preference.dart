class NotificationPreference {
  final String id;
  final String userId;
  final String category;
  final bool enabled;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreference({
    required this.id,
    required this.userId,
    required this.category,
    this.enabled = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
