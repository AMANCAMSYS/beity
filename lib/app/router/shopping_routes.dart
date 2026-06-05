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
import 'shopping_route_paths.dart';

String _explicitHomeId(GoRouterState state) {
  final queryHomeId = state.uri.queryParameters['homeId'];
  if (queryHomeId != null && queryHomeId.isNotEmpty) return queryHomeId;

  final extra = state.extra;
  if (extra is String && extra.isNotEmpty) return extra;
  if (extra is Map<String, dynamic>) {
    final extraHomeId = extra['homeId'];
    if (extraHomeId is String && extraHomeId.isNotEmpty) return extraHomeId;
  }
  return '';
}

List<GoRoute> shoppingRoutes(
  String Function(GoRouterState) getEffectiveHomeId,
) => [
  GoRoute(
    path: ShoppingRoutePaths.create,
    builder: (context, state) {
      final homeId = getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return CreateShoppingListScreen(homeId: homeId);
    },
  ),
  GoRoute(
    path: ShoppingRoutePaths.detailPattern,
    builder: (context, state) {
      final homeId = getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return ShoppingListDetailScreen(
        listId: state.pathParameters['id']!,
        homeId: homeId,
      );
    },
  ),
  GoRoute(
    path: ShoppingRoutePaths.addItemPattern,
    builder: (context, state) {
      final homeId = _explicitHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return AddItemScreen(listId: state.pathParameters['id']!, homeId: homeId);
    },
  ),
  GoRoute(
    path: ShoppingRoutePaths.editItemPattern,
    builder: (context, state) {
      final homeId = _explicitHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return EditItemScreen(
        listId: state.pathParameters['id']!,
        itemId: state.pathParameters['itemId']!,
        homeId: homeId,
      );
    },
  ),
  GoRoute(
    path: ShoppingRoutePaths.summaryPattern,
    builder: (context, state) =>
        ListSummaryScreen(listId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: ShoppingRoutePaths.aiSuggestionsPattern,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final String homeId =
          (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();

      return AiSuggestionsScreen(
        listId: state.pathParameters['id']!,
        listTitle: extra['listTitle'] ?? 'قائمة',
        homeId: homeId,
        homeType: extra['homeType'] ?? 'family',
      );
    },
    redirect: (context, state) {
      if (!FeatureFlags.enableAi) {
        return ShoppingRoutePaths.detail(state.pathParameters['id']!);
      }
      return null;
    },
  ),
  GoRoute(
    path: ShoppingRoutePaths.quickAddPattern,
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
    path: ShoppingRoutePaths.shoppingModePattern,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final String homeId =
          (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return ShoppingModeScreen(
        listId: state.pathParameters['id']!,
        homeId: homeId,
        listName: extra['listName'] ?? 'قائمة التسوق',
      );
    },
  ),
  GoRoute(
    path: ShoppingRoutePaths.activityPattern,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final String homeId =
          (extra['homeId'] as String?) ?? getEffectiveHomeId(state);
      if (homeId.isEmpty) return const NoActiveHomeWidget();
      return ListActivityScreen(
        homeId: homeId,
        listId: state.pathParameters['id']!,
        listName: extra['listName'] ?? 'القائمة',
      );
    },
  ),
];
