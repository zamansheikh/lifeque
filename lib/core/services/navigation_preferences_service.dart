import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's drawer-item order and the default home page.
class NavigationPreferencesService {
  static const _keyOrder = 'nav_item_order';
  static const _keyOnboardingDone = 'onboarding_done';

  /// The full ordered list of all routable main destinations.
  static const List<NavItem> allItems = [
    NavItem(route: '/', label: 'Tasks', iconData: Icons.task_alt_rounded),
    NavItem(
      route: '/todos',
      label: 'To-Dos',
      iconData: Icons.checklist_rounded,
    ),
    NavItem(
      route: '/expenses',
      label: 'Expense Tracker',
      iconData: Icons.account_balance_wallet_rounded,
    ),
    NavItem(
      route: '/medicines',
      label: 'Medicines',
      iconData: Icons.medication_rounded,
    ),
    NavItem(
      route: '/prayer-times',
      label: 'Prayer Times',
      iconData: Icons.mosque_rounded,
    ),
    NavItem(
      route: '/study-timer',
      label: 'Study Timer',
      iconData: Icons.timer_rounded,
    ),
  ];

  final SharedPreferences _prefs;
  NavigationPreferencesService(this._prefs);

  /// Returns the ordered list of nav items (user's preferred order).
  List<NavItem> getOrderedItems() {
    final saved = _prefs.getStringList(_keyOrder);
    if (saved == null || saved.isEmpty) return List.of(allItems);
    final result = <NavItem>[];
    for (final route in saved) {
      final match = allItems.where((i) => i.route == route);
      if (match.isNotEmpty) result.add(match.first);
    }
    // Append any new items not yet in saved order
    for (final item in allItems) {
      if (!result.any((r) => r.route == item.route)) result.add(item);
    }
    return result;
  }

  /// Saves a new item order.
  Future<void> saveOrder(List<NavItem> items) async {
    await _prefs.setStringList(_keyOrder, items.map((i) => i.route).toList());
  }

  /// The home page is the first item in the ordered list.
  String getHomeRoute() => getOrderedItems().first.route;

  bool isOnboardingDone() => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> markOnboardingDone() => _prefs.setBool(_keyOnboardingDone, true);
}

class NavItem {
  final String route;
  final String label;
  final IconData iconData;

  const NavItem({
    required this.route,
    required this.label,
    required this.iconData,
  });
}
