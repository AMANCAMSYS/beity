import 'package:go_router/go_router.dart';
import '../../features/shopping_lists/presentation/screens/create_shopping_list_screen.dart';
import '../../features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart';
import '../../features/shopping_lists/presentation/screens/add_item_screen.dart';
import '../../features/shopping_lists/presentation/screens/edit_item_screen.dart';
import '../../features/shopping_lists/presentation/screens/list_summary_screen.dart';
import '../../features/ai_suggestions/presentation/screens/ai_suggestions_screen.dart';
import '../../features/shopping_lists/presentation/screens/quick_add_screen.dart';
import '../../features/shopping_mode/presentation/screens/shopping_mode_screen.dart';
import '../../features/activity_logs/presentation/screens/list_activity_screen.dart';
import '../../features/homes/presentation/widgets/no_active_home_widget.dart';
import '../../core/config/feature_flags.dart';

List<GoRoute> shoppingRoutes(String Function(GoRouterState) getEffectiveHomeId) => [
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
    builder: (context, state) =>
        ShoppingListDetailScreen(listId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/shopping-list/:id/add-item',
    builder: (context, state) =>
        AddItemScreen(listId: state.pathParameters['id']!),
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
    builder: (context, state) =>
        ListSummaryScreen(listId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/shopping-list/:id/ai-suggestions',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final String homeId = (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      
      return AiSuggestionsScreen(
        listId: state.pathParameters['id']!,
        listTitle: extra['listTitle'] ?? 'قائمة',
        homeId: homeId,
        homeType: extra['homeType'] ?? 'family',
        existingItemNames:
            (extra['existingItemNames'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
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
      final String homeId = (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
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
      final String homeId = (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return ListActivityScreen(
        homeId: homeId,
        listId: state.pathParameters['id']!,
        listName: extra['listName'] ?? 'القائمة',
      );
    },
  ),
];
