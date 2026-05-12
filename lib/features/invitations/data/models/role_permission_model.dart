import '../../domain/entities/role_permission.dart';

class RolePermissionModel extends RolePermission {
  const RolePermissionModel({
    required super.id,
    required super.role,
    required super.permission,
    required super.allowed,
    required super.createdAt,
  });

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(
      id: json['id'] as String,
      role: json['role'] as String,
      permission: json['permission'] as String,
      allowed: json['allowed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'permission': permission,
      'allowed': allowed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RolePermissionModel copyWithModel({
    String? id,
    String? role,
    String? permission,
    bool? allowed,
    DateTime? createdAt,
  }) {
    return RolePermissionModel(
      id: id ?? this.id,
      role: role ?? this.role,
      permission: permission ?? this.permission,
      allowed: allowed ?? this.allowed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
