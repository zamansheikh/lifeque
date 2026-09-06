import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // GlobalKey for Navigator to enable navigation without context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Where a home-screen widget tap wants to land, if the app is still
  /// starting up.
  ///
  /// A cold tap can't just navigate: the app opens on the splash screen, which
  /// does its own permission checks and then `go`es to the user's home page —
  /// overwriting anything navigated to before it finishes. So the route is
  /// parked here and the splash uses it instead of the home route.
  static String? pendingWidgetRoute;

  /// Takes the parked route, if any, and clears it.
  static String? takePendingWidgetRoute() {
    final route = pendingWidgetRoute;
    pendingWidgetRoute = null;
    return route;
  }

  // Get the current context
  BuildContext? get currentContext => navigatorKey.currentContext;

  // Navigate to task detail page
  void navigateToTaskDetail(String taskId) {
    final context = currentContext;
    if (context != null) {
      debugPrint('🧭 Navigating to task detail: $taskId');
      context.push('/task-detail/$taskId');
    } else {
      debugPrint('🧭 ❌ No context available for navigation');
    }
  }

  // Navigate to edit task page
  void navigateToEditTask(String taskId) {
    final context = currentContext;
    if (context != null) {
      debugPrint('🧭 Navigating to edit task: $taskId');
      context.push('/edit-task/$taskId');
    } else {
      debugPrint('🧭 ❌ No context available for navigation');
    }
  }

  // Navigate to home page
  void navigateToHome() {
    final context = currentContext;
    if (context != null) {
      debugPrint('🧭 Navigating to home');
      context.go('/');
    } else {
      debugPrint('🧭 ❌ No context available for navigation');
    }
  }

  // Navigate to add task page
  void navigateToAddTask() {
    final context = currentContext;
    if (context != null) {
      debugPrint('🧭 Navigating to add task');
      context.push('/add-task');
    } else {
      debugPrint('🧭 ❌ No context available for navigation');
    }
  }

  // Pop current route
  void pop() {
    final context = currentContext;
    if (context != null && Navigator.canPop(context)) {
      debugPrint('🧭 Popping current route');
      Navigator.pop(context);
    } else {
      debugPrint('🧭 ❌ Cannot pop or no context available');
    }
  }
}
