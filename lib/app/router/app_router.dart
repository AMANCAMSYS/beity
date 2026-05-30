import 'dart:async';
import 'package:beity/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/widgets/main_shell.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import '../../features/homes/presentation/widgets/no_active_home_widget.dart';
import '../../features/shopping_lists/presentation/screens/shopping_lists_screen.dart';
import '../../features/shopping_mode/presentation/screens/shopping_mode_list_screen.dart';
import '../../features/activity_logs/presentation/screens/activity_feed_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

import '../../features/onboarding/data/onboarding_storage.dart';
import '../../features/onboarding/presentation/screens/welcome_onboarding_screen.dart';
import 'auth_routes.dart';
import 'shopping_routes.dart';
import 'home_routes.dart';
import 'feature_routes.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  String getEffectiveHomeId(GoRouterState state) {
    if (state.extra is String && (state.extra as String).isNotEmpty) {
      return state.extra as String;
    }
    final activeId = ref.read(cachedActiveHomeIdProvider);
    if (activeId != null && activeId.isNotEmpty) {
      return activeId;
    }
    final homes = ref.read(cachedUserHomesProvider);
    if (homes.isNotEmpty) {
      return homes.first.id;
    }
    return '';
  }

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: NotificationService.initialRoute ?? '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(
      SupabaseService.client.auth.onAuthStateChange,
    ),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page not found: ${state.uri.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Welcome onboarding (pre-auth, no shell)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeOnboardingScreen(),
      ),

      // Auth routes (no shell)
      ...authRoutes(),

      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Shopping Lists
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping-lists',
                builder: (context, state) {
                  final homeId = getEffectiveHomeId(state);
                  if (homeId.isEmpty) return const NoActiveHomeWidget();
                  return ShoppingListsScreen(homeId: homeId);
                },
              ),
            ],
          ),
          // Branch 2: Shopping Mode (select list)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping-mode',
                builder: (context, state) {
                  final homeId = getEffectiveHomeId(state);
                  if (homeId.isEmpty) return const NoActiveHomeWidget();
                  return ShoppingModeListScreen(homeId: homeId);
                },
              ),
            ],
          ),
          // Branch 3: Activity
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) {
                  final homeId = getEffectiveHomeId(state);
                  if (homeId.isEmpty) return const NoActiveHomeWidget();
                  return ActivityFeedScreen(homeId: homeId);
                },
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Other feature and sub routes
      ...homeRoutes(),
      ...shoppingRoutes(getEffectiveHomeId),
      ...featureRoutes(getEffectiveHomeId),
    ],
    redirect: (context, state) {
      final session = SupabaseService.client.auth.currentSession;
      final isAuthenticated = session != null && !session.isExpired;
      final isOnAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // 1. First-launch welcome onboarding (pre-auth, versioned check).
      if (OnboardingStorage.shouldShowWelcomeOnboarding() && !isOnOnboarding) {
        return '/onboarding';
      }

      // 2. Auth guard.
      if (!isAuthenticated && !isOnAuthRoute && !isOnOnboarding) {
        final fullPath = state.uri.toString();
        if (fullPath == '/' || fullPath.isEmpty) {
          return '/login';
        }
        return '/login?redirect=${Uri.encodeComponent(fullPath)}';
      }
      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/';
      }

      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
