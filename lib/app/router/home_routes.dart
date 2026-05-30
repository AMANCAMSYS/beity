import 'package:go_router/go_router.dart';
import '../../features/homes/presentation/screens/homes_list_screen.dart';
import '../../features/homes/presentation/screens/create_home_screen.dart';
import '../../features/homes/presentation/screens/home_members_screen.dart';
import '../../features/invitations/presentation/screens/invitations_list_screen.dart';
import '../../features/invitations/presentation/screens/send_invitation_screen.dart';
import '../../features/invitations/presentation/screens/manage_roles_screen.dart';

List<GoRoute> homeRoutes() => [
  GoRoute(
    path: '/homes',
    builder: (context, state) => const HomesListScreen(),
  ),
  GoRoute(
    path: '/homes/create',
    builder: (context, state) => const CreateHomeScreen(),
  ),
  GoRoute(
    path: '/homes/:id/members',
    builder: (context, state) =>
        HomeMembersScreen(homeId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/invitations',
    builder: (context, state) => const InvitationsListScreen(),
  ),
  GoRoute(
    path: '/homes/:id/invitations',
    builder: (context, state) =>
        InvitationsListScreen(homeId: state.pathParameters['id']),
  ),
  GoRoute(
    path: '/homes/:id/invitations/send',
    builder: (context, state) => SendInvitationScreen(
      homeId: state.pathParameters['id']!,
      homeName: state.extra as String? ?? 'المنزل',
    ),
  ),
  GoRoute(
    path: '/homes/:id/roles',
    builder: (context, state) => ManageRolesScreen(
      homeId: state.pathParameters['id']!,
      homeName: state.extra as String? ?? 'المنزل',
    ),
  ),
];
