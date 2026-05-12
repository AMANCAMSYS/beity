class HomeMember {
  final String id;
  final String homeId;
  final String userId;
  final String role;
  final String status;
  final DateTime joinedAt;
  final DateTime? deletedAt;

  const HomeMember({
    required this.id,
    required this.homeId,
    required this.userId,
    required this.role,
    this.status = 'active',
    required this.joinedAt,
    this.deletedAt,
  });

  factory HomeMember.fromJson(Map<String, dynamic> json) {
    return HomeMember(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      status: json['status'] as String? ?? 'active',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'user_id': userId,
      'role': role,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active' && deletedAt == null;
}
