import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/services/navigation_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('default order: tasks, prayer, reminders, birthdays, expenses, '
      'medicines, todos, timer', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = NavigationPreferencesService(
      await SharedPreferences.getInstance(),
    );
    expect(svc.getOrderedItems().map((i) => i.route), [
      '/',
      '/prayer-times',
      '/reminders',
      '/birthdays',
      '/expenses',
      '/medicines',
      '/todos',
      '/study-timer',
    ]);
    expect(svc.getHomeRoute(), '/');
  });

  test('a saved order wins over the default', () async {
    SharedPreferences.setMockInitialValues({
      'nav_item_order': ['/prayer-times', '/'],
    });
    final svc = NavigationPreferencesService(
      await SharedPreferences.getInstance(),
    );
    final routes = svc.getOrderedItems().map((i) => i.route).toList();
    expect(routes.take(2), ['/prayer-times', '/']);
    expect(routes.length, NavigationPreferencesService.allItems.length);
    expect(svc.getHomeRoute(), '/prayer-times');
  });
}
