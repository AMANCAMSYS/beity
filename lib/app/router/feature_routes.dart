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
import '../../features/billing/presentation/screens/subscription_plans_screen.dart';
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
import 'feature_route_paths.dart';

List<GoRoute> featureRoutes(
  String Function(GoRouterState) getEffectiveHomeId,
) => [
  GoRoute(
    path: FeatureRoutePaths.profile,
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.categories,
    builder: (context, state) {
      final homeId = getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return CategoriesListScreen(homeId: homeId);
    },
  ),
  GoRoute(
    path: FeatureRoutePaths.createCategory,
    builder: (context, state) {
      final homeId = getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return CreateCategoryScreen(homeId: homeId);
    },
  ),
  GoRoute(
    path: FeatureRoutePaths.units,
    builder: (context, state) => const UnitsListScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.createUnit,
    builder: (context, state) => const CreateUnitScreen(),
  ),
  GoRoute(
    path: '/activity/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final log = state.extra as ActivityLogModel?;
      return ActivityDetailScreen(activityId: id, initialLog: log);
    },
  ),
  GoRoute(
    path: FeatureRoutePaths.notifications,
    builder: (context, state) => const NotificationCenterScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.notificationPreferences,
    builder: (context, state) => const NotificationPreferencesScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.syncStatus,
    builder: (context, state) => const SyncStatusScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.subscriptionPlans,
    builder: (context, state) => const SubscriptionPlansScreen(),
  ),
  GoRoute(
    path: FeatureRoutePaths.inventory,
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
    path: FeatureRoutePaths.addInventory,
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
      final String homeId =
          (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
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
      final String homeId =
          (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
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
    path: FeatureRoutePaths.expenses,
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
    path: FeatureRoutePaths.addExpense,
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
    path: FeatureRoutePaths.expenseSummary,
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
    path: FeatureRoutePaths.balances,
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
    builder: (context, state) {
      final homeId = getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return ExpenseDetailScreen(
        expenseId: state.pathParameters['id']!,
        homeId: homeId,
      );
    },
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
