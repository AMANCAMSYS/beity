class FeatureFlags {
  FeatureFlags._();

  static const bool enableInventory = bool.fromEnvironment(
    'ENABLE_INVENTORY',
    defaultValue: true,
  );
  static const bool enableExpenses = bool.fromEnvironment(
    'ENABLE_EXPENSES',
    defaultValue: true,
  );
  static const bool enableTasks = bool.fromEnvironment(
    'ENABLE_TASKS',
    defaultValue: true,
  );
  static const bool enableAi = bool.fromEnvironment(
    'ENABLE_AI',
    defaultValue: true,
  );
}
