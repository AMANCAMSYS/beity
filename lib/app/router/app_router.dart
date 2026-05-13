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
import '../../features/categories/presentation/screens/categories_list_screen.dart';
import '../../features/categories/presentation/screens/create_category_screen.dart';
import '../../features/categories/presentation/screens/units_list_screen.dart';
import '../../features/categories/presentation/screens/create_unit_screen.dart';
import '../../features/shopping_lists/presentation/screens/shopping_lists_screen.dart';
import '../../features/shopping_lists/presentation/screens/create_shopping_list_screen.dart';
import '../../features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart';
import '../../features/shopping_lists/presentation/screens/add_item_screen.dart';
import '../../features/shopping_lists/presentation/screens/edit_item_screen.dart';
import '../../features/shopping_lists/presentation/screens/list_summary_screen.dart';
import '../../features/shopping_lists/presentation/screens/quick_add_screen.dart';
import '../../features/activity_logs/presentation/screens/activity_feed_screen.dart';
import '../../features/activity_logs/presentation/screens/list_activity_screen.dart';
import '../../features/activity_logs/presentation/screens/activity_detail_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/shopping_mode/presentation/screens/shopping_mode_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/add_inventory_item_screen.dart';
import '../../features/inventory/presentation/screens/inventory_item_detail_screen.dart';
import '../../features/inventory/presentation/screens/edit_inventory_item_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/presentation/screens/archived_tasks_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
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
      // Categories
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesListScreen(),
      ),
      GoRoute(
        path: '/categories/create',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return CreateCategoryScreen(homeId: homeId);
        },
      ),
      // Units
      GoRoute(
        path: '/units',
        builder: (context, state) => const UnitsListScreen(),
      ),
      GoRoute(
        path: '/units/create',
        builder: (context, state) => const CreateUnitScreen(),
      ),
      // Shopping Lists
      GoRoute(
        path: '/shopping-lists',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return ShoppingListsScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/shopping-lists/create',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return CreateShoppingListScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/shopping-list/:id',
        builder: (context, state) => ShoppingListDetailScreen(
          listId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shopping-list/:id/add-item',
        builder: (context, state) => AddItemScreen(
          listId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shopping-list/:id/edit-item/:itemId',
        builder: (context, state) => EditItemScreen(
          listId: state.pathParameters['id']!,
          itemId: state.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        path: '/shopping-list/:id/summary',
        builder: (context, state) => ListSummaryScreen(
          listId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shopping-list/:id/quick-add',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return QuickAddScreen(
            listId: state.pathParameters['id']!,
            homeId: homeId,
          );
        },
      ),
      GoRoute(
        path: '/shopping-list/:id/shopping-mode',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ShoppingModeScreen(
            listId: state.pathParameters['id']!,
            homeId: extra['homeId'] ?? '',
            listName: extra['listName'] ?? 'Shopping List',
          );
        },
      ),
      // Activity Logs
      GoRoute(
        path: '/activity',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return ActivityFeedScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/shopping-list/:id/activity',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ListActivityScreen(
            homeId: extra['homeId'] ?? '',
            listId: state.pathParameters['id']!,
            listName: extra['listName'] ?? 'القائمة',
          );
        },
      ),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) {
          final log = state.extra as dynamic;
          return ActivityDetailScreen(log: log);
        },
      ),
      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/notifications/preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      // Inventory
      GoRoute(
        path: '/inventory',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return InventoryScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/inventory/add',
        builder: (context, state) {
          final homeId = state.extra as String? ?? '';
          return AddInventoryItemScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return InventoryItemDetailScreen(
            itemId: state.pathParameters['id']!,
            homeId: extra['homeId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EditInventoryItemScreen(
            itemId: state.pathParameters['id']!,
            homeId: extra['homeId'] ?? '',
          );
        },
      ),
      // Tasks
      GoRoute(
        path: '/home/:id/tasks',
        builder: (context, state) => TaskListScreen(
          homeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/home/:id/tasks/add',
        builder: (context, state) => AddTaskScreen(
          homeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/home/:id/tasks/:taskId',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['taskId']!,
          homeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/home/:id/tasks/archived',
        builder: (context, state) => ArchivedTasksScreen(
          homeId: state.pathParameters['id']!,
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
