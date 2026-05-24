import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/widgets/main_shell.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/homes/presentation/screens/homes_list_screen.dart';
import '../../features/homes/presentation/screens/create_home_screen.dart';
import '../../features/homes/presentation/screens/home_members_screen.dart';

import '../../features/invitations/presentation/screens/invitations_list_screen.dart';
import '../../features/invitations/presentation/screens/send_invitation_screen.dart';
import '../../features/invitations/presentation/screens/manage_roles_screen.dart';
import '../../features/homes/presentation/providers/homes_provider.dart';
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
import '../../features/expenses/presentation/screens/expense_list_screen.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/expenses/presentation/screens/expense_summary_screen.dart';
import '../../features/expenses/presentation/screens/balances_screen.dart';
import '../../features/homes/presentation/widgets/no_active_home_widget.dart';
import '../../features/ai_suggestions/presentation/screens/ai_assistant_screen.dart';
import '../../core/config/feature_flags.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  String getEffectiveHomeId(GoRouterState state) {
    if (state.extra is String && (state.extra as String).isNotEmpty) {
      return state.extra as String;
    }
    final activeId = ref.read(activeHomeIdProvider).valueOrNull;
    if (activeId != null && activeId.isNotEmpty) {
      return activeId;
    }
    final homes = ref.read(userHomesProvider).valueOrNull;
    if (homes != null && homes.isNotEmpty) {
      return homes.first.id;
    }
    return '';
  }

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
        ),
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
                  return _ShoppingModeListScreen(homeId: homeId);
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
                builder: (context, state) => const _SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Sub-screens (pushed on top of shell)
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
      GoRoute(
        path: '/categories',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return CategoriesListScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/categories/create',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return CreateCategoryScreen(homeId: homeId);
        },
      ),
      GoRoute(
        path: '/units',
        builder: (context, state) => const UnitsListScreen(),
      ),
      GoRoute(
        path: '/units/create',
        builder: (context, state) => const CreateUnitScreen(),
      ),
      GoRoute(
        path: '/shopping-lists/create',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
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
        path: '/shopping-list/:id/ai-suggestions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AiAssistantScreen(
            listId: state.pathParameters['id']!,
            listTitle: extra['listTitle'] ?? 'قائمة',
            homeId: extra['homeId'] ?? '',
            homeType: extra['homeType'] ?? 'family',
            existingItemNames: (extra['existingItemNames'] as List<dynamic>?)?.cast<String>() ?? [],
          );
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableAi) {
            return '/shopping-list/${state.pathParameters['id']}';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/shopping-list/:id/quick-add',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
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
          final homeId = extra['homeId'] ?? getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return ShoppingModeScreen(
            listId: state.pathParameters['id']!,
            homeId: homeId,
            listName: extra['listName'] ?? 'قائمة التسوق',
          );
        },
      ),
      GoRoute(
        path: '/shopping-list/:id/activity',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final homeId = extra['homeId'] ?? getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return ListActivityScreen(
            homeId: homeId,
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/notifications/preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return InventoryScreen(homeId: homeId);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableInventory) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/inventory/add',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return AddInventoryItemScreen(homeId: homeId);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableInventory) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final homeId = extra['homeId'] ?? getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return InventoryItemDetailScreen(
            itemId: state.pathParameters['id']!,
            homeId: homeId,
          );
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableInventory) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final homeId = extra['homeId'] ?? getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return EditInventoryItemScreen(
            itemId: state.pathParameters['id']!,
            homeId: homeId,
          );
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableInventory) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return ExpenseListScreen(homeId: homeId);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableExpenses) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/expenses/add',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return AddExpenseScreen(homeId: homeId);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableExpenses) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/expenses/summary',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return ExpenseSummaryScreen(homeId: homeId);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableExpenses) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/expenses/balances',
        builder: (context, state) {
          final homeId = getEffectiveHomeId(state);
          if (homeId.isEmpty) return const NoActiveHomeWidget();
          return BalancesScreen(homeId: homeId);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableExpenses) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (context, state) => ExpenseDetailScreen(
          expenseId: state.pathParameters['id']!,
        ),
        redirect: (context, state) {
          if (!FeatureFlags.enableExpenses) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/home/:id/tasks',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (id.isEmpty) return const NoActiveHomeWidget();
          return TaskListScreen(homeId: id);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableTasks) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/home/:id/tasks/add',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (id.isEmpty) return const NoActiveHomeWidget();
          return AddTaskScreen(homeId: id);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableTasks) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/home/:id/tasks/archived',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (id.isEmpty) return const NoActiveHomeWidget();
          return ArchivedTasksScreen(homeId: id);
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableTasks) return '/';
          return null;
        },
      ),
      GoRoute(
        path: '/home/:id/tasks/:taskId',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (id.isEmpty) return const NoActiveHomeWidget();
          return TaskDetailScreen(
            taskId: state.pathParameters['taskId']!,
            homeId: id,
          );
        },
        redirect: (context, state) {
          if (!FeatureFlags.enableTasks) return '/';
          return null;
        },
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isOnAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isOnAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/';
      }

      return null;
    },
  );
});

// Helper screen for Shopping Mode tab (list selection)
class _ShoppingModeListScreen extends StatelessWidget {
  final String homeId;
  const _ShoppingModeListScreen({required this.homeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وضع التسوق')),
      body: const Center(
        child: Text('اختر قائمة لبدء وضع التسوق'),
      ),
    );
  }
}

// Helper screen for Settings tab
class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _settingsItem(context, Icons.person, 'الملف الشخصي', '/profile'),
                _settingsItem(context, Icons.home, 'إدارة المنازل', '/homes'),
                _settingsItem(context, Icons.category, 'التصنيفات', '/categories'),
                _settingsItem(context, Icons.straighten, 'وحدات القياس', '/units'),
                _settingsItem(context, Icons.inventory_2, 'المخزون', '/inventory'),
                _settingsItem(context, Icons.receipt_long, 'المصروفات', '/expenses'),
                _settingsItem(context, Icons.notifications, 'إعدادات الإشعارات', '/notifications/preferences'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem(BuildContext context, IconData icon, String label, String route) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(label, textDirection: TextDirection.rtl),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => context.push(route),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

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
