enum HomeRole {
  owner,
  admin,
  member,
  viewer;

  String get displayName {
    switch (this) {
      case HomeRole.owner:
        return 'المالك';
      case HomeRole.admin:
        return 'مدير';
      case HomeRole.member:
        return 'عضو';
      case HomeRole.viewer:
        return 'مشاهد';
    }
  }

  bool get canInvite =>
      this == HomeRole.owner || this == HomeRole.admin;

  bool get canManageLists =>
      this == HomeRole.owner || this == HomeRole.admin;

  bool get canEditItems =>
      this == HomeRole.owner ||
      this == HomeRole.admin ||
      this == HomeRole.member;

  bool get canView => true;

  bool get canManageMembers =>
      this == HomeRole.owner || this == HomeRole.admin;

  bool get canRemoveMembers =>
      this == HomeRole.owner || this == HomeRole.admin;

  bool get canTransferOwnership => this == HomeRole.owner;

  bool get canChangeRole => this == HomeRole.owner;

  bool canChangeRoleTo(HomeRole newRole) {
    if (this == HomeRole.owner) return true;
    if (this == HomeRole.admin) {
      return newRole == HomeRole.member || newRole == HomeRole.viewer;
    }
    return false;
  }

  bool canRemoveMember(HomeRole memberRole) {
    if (this == HomeRole.owner) return true;
    if (this == HomeRole.admin) {
      return memberRole != HomeRole.admin && memberRole != HomeRole.owner;
    }
    return false;
  }
}
