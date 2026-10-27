import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/services/notification_service.dart';
import 'package:lifeque/features/expenses/domain/entities/expense_category.dart';
import 'package:lifeque/features/subscriptions/data/subscription_expense.dart';
import 'package:lifeque/features/subscriptions/data/subscription_repository.dart';
import 'package:lifeque/features/subscriptions/domain/subscription.dart';
import 'package:lifeque/features/subscriptions/presentation/subscription_cubit.dart';
import 'package:lifeque/features/subscriptions/presentation/subscriptions_page.dart';
import 'package:lifeque/injection_container.dart' as di;
import 'package:lifeque/l10n/app_localizations.dart';

class MemoryRepo implements SubscriptionRepository {
  final Map<String, Subscription> rows = {};
  @override
  Future<List<Subscription>> all() async =>
      rows.values.toList()
        ..sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal));
  @override
  Future<Subscription?> byId(String id) async => rows[id];
  @override
  Future<void> save(Subscription s) async => rows[s.id] = s;
  @override
  Future<void> delete(String id) async => rows.remove(id);
}

class RecordingReminders implements SubscriptionReminders {
  final scheduled = <String, Subscription>{};
  final cancelled = <String>[];
  @override
  Future<void> schedule(Subscription s) async => scheduled[s.id] = s;
  @override
  Future<void> cancel(String id) async => cancelled.add(id);
}

Subscription sub({
  String id = 'n',
  String name = 'Netflix',
  double amount = 500,
  String currency = 'BDT',
  BillingCycle cycle = BillingCycle.monthly,
  required DateTime next,
  int remind = 3,
  bool trial = false,
  bool active = true,
  SubscriptionCategory category = SubscriptionCategory.streaming,
  double? lastPaidLocal,
}) => Subscription(
  id: id,
  name: name,
  amount: amount,
  currency: currency,
  cycle: cycle,
  nextRenewal: next,
  remindDaysBefore: remind,
  isTrial: trial,
  isActive: active,
  category: category,
  lastPaidLocal: lastPaidLocal,
  createdAt: DateTime(2026),
);

void main() {
  group('billing dates', () {
    test('a month-end renewal comes back to the 31st', () {
      var d = DateTime(2026, 1, 31);
      final seen = <DateTime>[];
      for (var i = 0; i < 3; i++) {
        d = Subscription.advance(d, BillingCycle.monthly, 31);
        seen.add(d);
      }
      expect(seen, [
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('weekly, quarterly and yearly (leap day) steps', () {
      expect(
        Subscription.advance(DateTime(2026, 12, 29), BillingCycle.weekly, 29),
        DateTime(2027, 1, 5),
      );
      expect(
        Subscription.advance(
          DateTime(2026, 11, 30),
          BillingCycle.quarterly,
          30,
        ),
        DateTime(2027, 2, 28),
      );
      expect(
        Subscription.advance(DateTime(2028, 2, 29), BillingCycle.yearly, 29),
        DateTime(2029, 2, 28),
      );
    });

    test('previous renewal undoes a step', () {
      final s = sub(next: DateTime(2026, 3, 31));
      expect(s.previousRenewal, DateTime(2026, 2, 28));
    });

    test('days left, status and progress through the cycle', () {
      final now = DateTime(2026, 10, 27, 15);
      final s = sub(next: DateTime(2026, 11, 1));
      expect(s.daysUntil(now), 5);
      expect(s.statusAt(now), RenewalStatus.upcoming);
      expect(
        sub(next: DateTime(2026, 10, 29)).statusAt(now),
        RenewalStatus.dueSoon,
      );
      expect(
        sub(next: DateTime(2026, 10, 25)).statusAt(now),
        RenewalStatus.overdue,
      );
      expect(
        sub(next: DateTime(2026, 11, 1), active: false).statusAt(now),
        RenewalStatus.cancelled,
      );
      // 1 Oct → 1 Nov: about 26 of 31 days gone.
      expect(s.progressAt(now), closeTo(0.85, 0.02));
    });

    test('monthly share of each cycle', () {
      expect(BillingCycle.yearly.monthlyShare(1200), 100);
      expect(BillingCycle.quarterly.monthlyShare(300), 100);
      expect(BillingCycle.weekly.monthlyShare(120), closeTo(520, 0.01));
    });

    test('foreign currency counts in taka only once a charge is known', () {
      final usd = sub(currency: 'USD', amount: 10, next: DateTime(2026, 11));
      expect(usd.monthlyCostLocal, isNull);
      expect(
        usd.copyWith(lastPaidLocal: 1230).monthlyCostLocal,
        1230,
        reason: 'what the card showed last time',
      );
    });

    test('paying moves one cycle on and ends a trial', () {
      final paid = sub(
        next: DateTime(2026, 1, 31),
        trial: true,
      ).afterPayment(paidAt: DateTime(2026, 1, 31, 9));
      expect(paid.nextRenewal, DateTime(2026, 2, 28));
      expect(paid.isTrial, isFalse);
      expect(paid.lastPaidAt, DateTime(2026, 1, 31, 9));
      // And the next one goes back to the 31st.
      expect(
        paid.afterPayment(paidAt: DateTime(2026, 2, 28)).nextRenewal,
        DateTime(2026, 3, 31),
      );
    });

    test('a row survives the database', () {
      final s = sub(
        next: DateTime(2026, 11, 15),
        currency: 'USD',
        cycle: BillingCycle.yearly,
        trial: true,
        lastPaidLocal: 2400,
      ).copyWith(note: 'Visa ending 42');
      expect(Subscription.fromMap(s.toMap()), s.copyWith(billingDay: 15));
    });
  });

  group('the cubit', () {
    late MemoryRepo repo;
    late RecordingReminders reminders;
    late List<(String, double)> logged;
    late SubscriptionCubit cubit;

    setUp(() {
      repo = MemoryRepo();
      reminders = RecordingReminders();
      logged = [];
      cubit = SubscriptionCubit(
        repo,
        reminders,
        (s, amount, _) async => logged.add((s.name, amount)),
        now: () => DateTime(2026, 10, 27, 10),
      );
    });

    test('saving stores it and schedules its reminders', () async {
      await cubit.save(sub(next: DateTime(2026, 11, 5)));
      expect(cubit.state.items, hasLength(1));
      expect(reminders.scheduled, contains('n'));
    });

    test('paid: next renewal, expense in taka, reminders moved', () async {
      final s = sub(next: DateTime(2026, 10, 28));
      await cubit.save(s);
      await cubit.markPaid(s, amountLocal: 500);
      expect(repo.rows['n']!.nextRenewal, DateTime(2026, 11, 28));
      expect(logged, [('Netflix', 500.0)]);
      expect(reminders.scheduled['n']!.nextRenewal, DateTime(2026, 11, 28));
    });

    test('a foreign-currency charge is remembered for next time', () async {
      final s = sub(currency: 'USD', amount: 10, next: DateTime(2026, 10, 28));
      await cubit.save(s);
      await cubit.markPaid(s, amountLocal: 1225);
      expect(repo.rows['n']!.lastPaidLocal, 1225);
      expect(repo.rows['n']!.monthlyCostLocal, 1225);
    });

    test('paid without logging, and without an amount', () async {
      final s = sub(next: DateTime(2026, 10, 28));
      await cubit.save(s);
      await cubit.markPaid(s, amountLocal: 500, logExpense: false);
      await cubit.markPaid(repo.rows['n']!, amountLocal: null);
      expect(logged, isEmpty);
      expect(repo.rows['n']!.nextRenewal, DateTime(2026, 12, 28));
    });

    test('delete cancels its reminders', () async {
      await cubit.save(sub(next: DateTime(2026, 11, 5)));
      await cubit.delete('n');
      expect(reminders.cancelled, ['n']);
      expect(cubit.state.items, isEmpty);
    });
  });

  test('sections: late, this week, this month, later, cancelled', () {
    final now = DateTime(2026, 10, 27);
    final g = groupSubscriptions([
      sub(id: 'late', next: DateTime(2026, 10, 20)),
      sub(id: 'week', next: DateTime(2026, 11, 2)),
      sub(id: 'month', next: DateTime(2026, 11, 20)),
      sub(id: 'later', next: DateTime(2027, 1, 1)),
      sub(id: 'gone', next: DateTime(2026, 11, 2), active: false),
    ], now);
    expect(g[SubscriptionGroup.overdue]!.single.id, 'late');
    expect(g[SubscriptionGroup.week]!.single.id, 'week');
    expect(g[SubscriptionGroup.month]!.single.id, 'month');
    expect(g[SubscriptionGroup.later]!.single.id, 'later');
    expect(g[SubscriptionGroup.cancelled]!.single.id, 'gone');
  });

  test('a renewal becomes one bought expense item, sensibly filed', () {
    Intl.defaultLocale = 'en';
    final e = renewalExpense(
      sub(next: DateTime(2026, 11)),
      500,
      DateTime(2026, 10, 27),
    );
    expect(e.title, 'Netflix');
    expect(e.items.single.amount, 500);
    expect(e.items.single.isPurchased, isTrue);
    expect(e.items.single.category, ExpenseCategory.entertainment);
    expect(
      expenseCategoryFor(SubscriptionCategory.internet),
      ExpenseCategory.utilities,
    );
    expect(
      expenseCategoryFor(SubscriptionCategory.cloud),
      ExpenseCategory.bills,
    );
  });

  test('notification ids: stable, distinct per slot, valid ints', () {
    final a = NotificationService.subscriptionNotificationId('abc', 0);
    expect(NotificationService.subscriptionNotificationId('abc', 0), a);
    expect(NotificationService.subscriptionNotificationId('abc', 1), a + 1);
    expect(NotificationService.subscriptionNotificationId('abd', 0), isNot(a));
    expect(a, lessThan(2147483647));
    expect(a, greaterThanOrEqualTo(1800000000));
  });

  group('the screen', () {
    late MemoryRepo repo;
    setUpAll(() async => initializeDateFormatting());
    setUp(() async {
      repo = MemoryRepo();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await repo.save(sub(id: 'a', next: today.add(const Duration(days: 2))));
      await repo.save(
        sub(
          id: 'b',
          name: 'Google One',
          amount: 1200,
          cycle: BillingCycle.yearly,
          category: SubscriptionCategory.cloud,
          next: today.add(const Duration(days: 90)),
        ),
      );
      await repo.save(
        sub(
          id: 'c',
          name: 'ChatGPT Plus',
          amount: 20,
          currency: 'USD',
          category: SubscriptionCategory.software,
          next: today.subtract(const Duration(days: 1)),
        ),
      );
      await di.sl.reset();
      di.sl.registerSingleton(
        SubscriptionCubit(repo, RecordingReminders(), (_, _, _) async {}),
      );
    });
    tearDown(() {
      Intl.defaultLocale = null;
      return di.sl.reset();
    });

    testWidgets('renders in Bangla: totals, sections, pay buttons', (
      tester,
    ) async {
      Intl.defaultLocale = 'bn';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('bn'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: const SubscriptionsPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // ৳500 a month + ৳1200 a year = ৳600 a month in taka.
      expect(find.text('৳৬০০'), findsOneWidget);
      expect(find.textContaining('বিদেশি মুদ্রায়'), findsOneWidget);
      expect(find.text('পরিশোধ বাকি'), findsOneWidget);
      expect(find.text('এই সপ্তাহে'), findsOneWidget);
      // Due in 2 days and 1 day late: both offer "paid".
      expect(find.byKey(const Key('sub-pay-a')), findsOneWidget);
      expect(find.byKey(const Key('sub-pay-c')), findsOneWidget);
      expect(find.byKey(const Key('sub-pay-b')), findsNothing);
    });
  });
}
