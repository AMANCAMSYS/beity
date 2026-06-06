class FeatureRoutePaths {
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const categories = '/categories';
  static const createCategory = '/categories/create';
  static const units = '/units';
  static const createUnit = '/units/create';
  static const notifications = '/notifications';
  static const notificationPreferences = '/notifications/preferences';
  static const syncStatus = '/settings/sync-status';
  static const subscriptionPlans = '/settings/subscription';

  // Inventory
  static const inventory = '/inventory';
  static const addInventory = '/inventory/add';

  static String inventoryItem(String id) => '/inventory/$id';
  static String editInventoryItem(String id) => '/inventory/$id/edit';

  // Expenses
  static const expenses = '/expenses';
  static const addExpense = '/expenses/add';
  static const expenseSummary = '/expenses/summary';
  static const balances = '/expenses/balances';

  static String expense(String id) => '/expenses/$id';

  // Tasks
  static String tasks(String homeId) => '/home/$homeId/tasks';
  static String addTask(String homeId) => '/home/$homeId/tasks/add';
  static String archivedTasks(String homeId) => '/home/$homeId/tasks/archived';
  static String task(String homeId, String taskId) =>
      '/home/$homeId/tasks/$taskId';

  // Activity
  static String activityDetail(String id) => '/activity/$id';
}
