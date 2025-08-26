import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // GlobalKey for Navigator to enable navigation without context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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
