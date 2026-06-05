import 'dart:async';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/widgets/main_shell.dart';
import '../../features/homes/data/models/home_selection.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
import '../../features/homes/presentation/widgets/no_active_home_widget.dart';
import '../../features/shopping_lists/presentation/screens/shopping_lists_screen.dart';
import '../../features/shopping_mode/presentation/screens/shopping_mode_list_screen.dart';
import '../../features/activity_logs/presentation/screens/activity_feed_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

import '../../features/onboarding/data/onboarding_storage.dart';
import '../../features/onboarding/presentation/screens/welcome_onboarding_screen.dart';
import 'auth_routes.dart';
import 'shopping_route_paths.dart';
import 'shopping_routes.dart';
import 'home_routes.dart';
import 'feature_routes.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String getEffectiveHomeId(GoRouterState state, Ref ref) {
  final queryHomeId = state.uri.queryParameters['homeId'];
  if (queryHomeId != null && queryHomeId.isNotEmpty) {
    return queryHomeId;
  }
  if (state.extra is String && (state.extra as String).isNotEmpty) {
    return state.extra as String;
  }
  if (state.extra is Map<String, dynamic>) {
    final extraMap = state.extra as Map<String, dynamic>;
    if (extraMap['homeId'] is String &&
        (extraMap['homeId'] as String).isNotEmpty) {
      return extraMap['homeId'] as String;
    }
  }
  final homes = ref.read(cachedUserHomesProvider);
  final activeId = ref.read(cachedActiveHomeIdProvider);
  final activeHome = findAvailableHomeById(homes, activeId);
  if (activeHome != null) {
    return activeHome.id;
  }
  return newestAvailableHome(homes)?.id ?? '';
}

String getEffectiveHomeName(GoRouterState state, Ref ref) {
  if (state.extra is String && (state.extra as String).isNotEmpty) {
    return state.extra as String;
  }
  if (state.extra is Map<String, dynamic>) {
    final extraMap = state.extra as Map<String, dynamic>;
    if (extraMap['homeName'] is String &&
        (extraMap['homeName'] as String).isNotEmpty) {
      return extraMap['homeName'] as String;
    }
  }

  final homeId = state.pathParameters['id'] ?? getEffectiveHomeId(state, ref);
  if (homeId.isNotEmpty) {
    final homes = ref.read(cachedUserHomesProvider);
    for (final home in homes) {
      if (home.id == homeId) return home.name;
    }
  }
  return 'Home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: NotificationService.initialRoute ?? '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(
      SupabaseService.client.auth.onAuthStateChange,
    ),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(context.translate('page_not_found_title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.translate('page_not_found_message')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text(context.translate('go_to_dashboard')),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Welcome onboarding (pre-auth, no shell)
      GoRoute(
        path: '/welcome-onboarding',
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
                path: ShoppingRoutePaths.lists,
                builder: (context, state) {
                  final homeId = getEffectiveHomeId(state, ref);
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
                path: ShoppingRoutePaths.mode,
                builder: (context, state) {
                  final homeId = getEffectiveHomeId(state, ref);
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
                  final homeId = getEffectiveHomeId(state, ref);
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
      ...homeRoutes(
        resolveHomeName: (state) => getEffectiveHomeName(state, ref),
      ),
      ...shoppingRoutes((state) => getEffectiveHomeId(state, ref)),
      ...featureRoutes((state) => getEffectiveHomeId(state, ref)),
    ],
    redirect: (context, state) {
      final session = SupabaseService.client.auth.currentSession;
      final isAuthenticated = session != null;
      final isOnAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnOnboarding = state.matchedLocation == '/welcome-onboarding';

      // 1. First-launch welcome onboarding (pre-auth, versioned check).
      if (OnboardingStorage.shouldShowWelcomeOnboarding() && !isOnOnboarding) {
        return '/welcome-onboarding';
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
