import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../notification_service.dart';

class NotificationNavigationHelper {
  static void handleNotificationTap(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState>? navigatorKey,
  ) {
    final route = data['route'] as String?;
    if (route != null) {
      navigateToRoute(route, navigatorKey);
    }
  }

  static void navigateToRoute(
    String route,
    GlobalKey<NavigatorState>? navigatorKey,
  ) {
    if (route.isEmpty || !route.startsWith('/')) return;

    if (navigatorKey?.currentContext != null) {
      GoRouter.of(navigatorKey!.currentContext!).go(route);
      if (NotificationService.initialRoute == route) {
        NotificationService.initialRoute = null;
      }
    } else {
      NotificationService.initialRoute = route;
      schedulePendingRouteNavigation(navigatorKey);
    }
  }

  static void schedulePendingRouteNavigation(
    GlobalKey<NavigatorState>? navigatorKey,
  ) {
    if (NotificationService.pendingRouteNavigationScheduled ||
        NotificationService.initialRoute == null) {
      return;
    }
    NotificationService.pendingRouteNavigationScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.pendingRouteNavigationScheduled = false;

      final route = NotificationService.initialRoute;
      final context = navigatorKey?.currentContext;
      if (route == null || context == null) {
        if (NotificationService.initialRoute != null) {
          schedulePendingRouteNavigation(navigatorKey);
        }
        return;
      }

      NotificationService.initialRoute = null;
      GoRouter.of(context).go(route);
    });
  }
}
