import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central registry for all stable GlobalKeys used by the in-app tour.
///
/// Keys are created once and never recreated, preventing build-loop issues.
/// Widgets that want to be tour targets retrieve their key from this registry.
class AppTourTargetRegistry {
  AppTourTargetRegistry._();

  static final homeHeaderKey = GlobalKey(debugLabel: 'tour_home_header');
  static final quickAddKey = GlobalKey(debugLabel: 'tour_quick_add');
  static final shoppingModeActionKey =
      GlobalKey(debugLabel: 'tour_shopping_mode_action');
  static final aiSuggestionsKey =
      GlobalKey(debugLabel: 'tour_ai_suggestions');

  static final listsTabKey = GlobalKey(debugLabel: 'tour_lists_tab');
  static final shoppingTabKey =
      GlobalKey(debugLabel: 'tour_shopping_tab');
  static final activityTabKey =
      GlobalKey(debugLabel: 'tour_activity_tab');
  static final drawerMenuKey = GlobalKey(debugLabel: 'tour_drawer_menu');

  static final expensesAddKey = GlobalKey(debugLabel: 'tour_expenses_add');
  static final expensesSummaryKey = GlobalKey(debugLabel: 'tour_expenses_summary');
  static final expensesBalancesKey = GlobalKey(debugLabel: 'tour_expenses_balances');
  static final expensesFilterKey = GlobalKey(debugLabel: 'tour_expenses_filter');
  static final inventoryAddKey = GlobalKey(debugLabel: 'tour_inventory_add');
  static final inventoryFilterKey = GlobalKey(debugLabel: 'tour_inventory_filter');
  static final tasksAddKey = GlobalKey(debugLabel: 'tour_tasks_add');
  static final tasksQuickAddKey = GlobalKey(debugLabel: 'tour_tasks_quick_add');
  static final tasksFilterKey = GlobalKey(debugLabel: 'tour_tasks_filter');

  static final categoriesAddKey = GlobalKey(debugLabel: 'tour_categories_add');
  static final categoriesFilterKey = GlobalKey(debugLabel: 'tour_categories_filter');
  static final unitsAddKey = GlobalKey(debugLabel: 'tour_units_add');
  static final unitsFilterKey = GlobalKey(debugLabel: 'tour_units_filter');

  /// Returns `true` if the widget behind [key] is currently in the tree.
  static bool isMounted(GlobalKey key) => key.currentContext != null;
}

/// Riverpod provider exposes the singleton registry.
final appTourTargetRegistryProvider = Provider<AppTourTargetRegistry>((_) {
  return AppTourTargetRegistry._();
});
