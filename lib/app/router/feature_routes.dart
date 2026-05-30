import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/homes/presentation/screens/onboarding_screen.dart';
import '../../features/categories/presentation/screens/categories_list_screen.dart';
import '../../features/categories/presentation/screens/create_category_screen.dart';
import '../../features/categories/presentation/screens/units_list_screen.dart';
import '../../features/categories/presentation/screens/create_unit_screen.dart';
import '../../features/activity_logs/presentation/screens/activity_detail_screen.dart';
import '../../features/activity_logs/data/models/activity_log_model.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/offline_queue/presentation/screens/sync_status_screen.dart';
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
import '../../core/config/feature_flags.dart';

List<GoRoute> featureRoutes(String Function(GoRouterState) getEffectiveHomeId) => [
  GoRoute(
    path: '/profile',
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: '/onboarding',
    builder: (context, state) => const OnboardingScreen(),
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
    path: '/activity/:id',
    builder: (context, state) {
      final log = state.extra as ActivityLogModel;
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
    path: '/settings/sync-status',
    builder: (context, state) => const SyncStatusScreen(),
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
      final String homeId = (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
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
      final String homeId = (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
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
    builder: (context, state) =>
        ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
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
];
