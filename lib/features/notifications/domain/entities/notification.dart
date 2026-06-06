class AppNotification {
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

  const AppNotification({
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
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

  AppNotification copyWith({bool? isRead}) {
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
      isRead: isRead ?? this.isRead,
      batchKey: batchKey,
      createdAt: createdAt,
    );
  }
}
