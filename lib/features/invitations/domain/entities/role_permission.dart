class RolePermission {
  final String id;
  final String role;
  final String permission;
  final bool allowed;
  final DateTime createdAt;

  const RolePermission({
    required this.id,
    required this.role,
    required this.permission,
    required this.allowed,
    required this.createdAt,
  });

  RolePermission copyWith({
    String? id,
    String? role,
    String? permission,
    bool? allowed,
    DateTime? createdAt,
  }) {
    return RolePermission(
      id: id ?? this.id,
      role: role ?? this.role,
      permission: permission ?? this.permission,
      allowed: allowed ?? this.allowed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PermissionConstants {
  static const String canInvite = 'can_invite';
  static const String canManageLists = 'can_manage_lists';
  static const String canEditItems = 'can_edit_items';
  static const String canView = 'can_view';
  static const String canManageMembers = 'can_manage_members';
  static const String canRemoveMembers = 'can_remove_members';
  static const String canTransferOwnership = 'can_transfer_ownership';

  static const List<String> allPermissions = [
    canInvite,
    canManageLists,
    canEditItems,
    canView,
    canManageMembers,
    canRemoveMembers,
    canTransferOwnership,
  ];
}
