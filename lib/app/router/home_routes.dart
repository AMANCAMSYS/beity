import 'package:go_router/go_router.dart';
import '../../features/homes/presentation/screens/homes_list_screen.dart';
import '../../features/homes/presentation/screens/create_home_screen.dart';
import '../../features/homes/presentation/screens/home_members_screen.dart';
import '../../features/invitations/presentation/screens/invitations_list_screen.dart';
import '../../features/invitations/presentation/screens/send_invitation_screen.dart';
import '../../features/invitations/presentation/screens/manage_roles_screen.dart';
import 'home_route_paths.dart';

typedef HomeNameResolver = String Function(GoRouterState state);

List<GoRoute> homeRoutes({required HomeNameResolver resolveHomeName}) => [
  GoRoute(path: HomeRoutePaths.homes, builder: (context, state) => const HomesListScreen()),
  GoRoute(
    path: HomeRoutePaths.createHome,
    builder: (context, state) => const CreateHomeScreen(),
  ),
  GoRoute(
    path: '/homes/:id/members',
    builder: (context, state) =>
        HomeMembersScreen(homeId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: HomeRoutePaths.invitations,
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
      homeName: resolveHomeName(state),
    ),
  ),
  GoRoute(
    path: '/homes/:id/roles',
    builder: (context, state) => ManageRolesScreen(
      homeId: state.pathParameters['id']!,
      homeName: resolveHomeName(state),
    ),
  ),
];
