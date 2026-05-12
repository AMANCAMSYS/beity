import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/homes/presentation/screens/homes_list_screen.dart';
import '../../features/homes/presentation/screens/create_home_screen.dart';
import '../../features/homes/presentation/screens/home_members_screen.dart';
import '../../features/homes/presentation/screens/onboarding_screen.dart';
import '../../features/invitations/presentation/screens/invitations_list_screen.dart';
import '../../features/invitations/presentation/screens/send_invitation_screen.dart';
import '../../features/invitations/presentation/screens/manage_roles_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
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
        builder: (context, state) => HomeMembersScreen(
          homeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/invitations',
        builder: (context, state) => const InvitationsListScreen(),
      ),
      GoRoute(
        path: '/homes/:id/invitations',
        builder: (context, state) => InvitationsListScreen(
          homeId: state.pathParameters['id'],
        ),
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
    ],
    redirect: (context, state) {
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isOnAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isOnAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isOnAuthRoute) {
        return '/';
      }

      return null;
    },
  );
});
