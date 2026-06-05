import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/invitations/presentation/providers/roles_provider.dart';

class HomePermissions {
  final bool canView;
  final bool canEdit;
  final bool canManageMembers;

  const HomePermissions({
    this.canView = false,
    this.canEdit = false,
    this.canManageMembers = false,
  });

  bool get isViewer => canView && !canEdit;
}

final currentHomePermissionsProvider = Provider.family<HomePermissions, String>(
  (ref, homeId) {
    final role = ref.watch(currentHomeRoleProvider(homeId));

    return HomePermissions(
      canView: role.canView,
      canEdit: role.canEditItems,
      canManageMembers: role.canManageMembers,
    );
  },
);
